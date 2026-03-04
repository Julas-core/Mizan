from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from datetime import datetime, timezone

from app.api import dependencies
from app.models.reflection import Purchase as PurchaseModel, Reflection as ReflectionModel
from app.schemas.reflection import PurchaseUpdateStatus, Purchase as PurchaseSchema, ReflectionCreate, Reflection as ReflectionSchema
from app.services.llm_service import generate_reflection_insight
from app.services.idempotency_service import get_idempotent_payload, persist_idempotent_payload
from typing import List

router = APIRouter()

@router.get("/{user_id}/history", response_model=List[PurchaseSchema])
def get_user_purchase_history(user_id: str, status_filter: str = "ABANDONED", db: Session = Depends(dependencies.get_db)):
    """
    Returns a list of purchases with a specific status (defaults to ABANDONED for 'Passed' items).
    """
    purchases = (
        db.query(PurchaseModel)
        .filter(
            PurchaseModel.user_id == user_id,
            PurchaseModel.status == status_filter
        )
        .order_by(PurchaseModel.created_at.desc())
        .limit(20) # Keeping it to recent history for now
        .all()
    )
    return purchases

@router.get("/{user_id}/latest-evaluated", response_model=PurchaseSchema)
def get_latest_evaluated_purchase(user_id: str, db: Session = Depends(dependencies.get_db)):
    """
    Returns the latest purchase currently awaiting user reflection.
    """
    purchase = (
        db.query(PurchaseModel)
        .filter(
            PurchaseModel.user_id == user_id,
            PurchaseModel.status == "EVALUATED"
        )
        .order_by(PurchaseModel.created_at.desc())
        .first()
    )

    if not purchase:
        raise HTTPException(status_code=404, detail="No evaluated purchases found")

    return purchase

@router.patch("/{purchase_id}/status", response_model=PurchaseSchema)
def update_purchase_status(
    purchase_id: str,
    status_update: PurchaseUpdateStatus,
    db: Session = Depends(dependencies.get_db),
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
):
    """
    Updates the outcome of an evaluated purchase.
    Valid statuses: BOUGHT, ABANDONED
    """
    valid_statuses = {"BOUGHT", "ABANDONED"}
    if status_update.status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {valid_statuses}")

    endpoint_key = f"purchases.status:{purchase_id}"
    if idempotency_key:
        replay_payload = get_idempotent_payload(db, endpoint_key, idempotency_key)
        if replay_payload:
            return PurchaseSchema(**replay_payload)

    purchase = db.query(PurchaseModel).filter(PurchaseModel.id == purchase_id).first()
    if not purchase:
        raise HTTPException(status_code=404, detail="Purchase evaluation not found")

    purchase.status = status_update.status

    response_payload = {
        "id": purchase.id,
        "user_id": purchase.user_id,
        "item_name": purchase.item_name,
        "price_cents": purchase.price_cents,
        "category": purchase.category,
        "affordability_score": purchase.affordability_score,
        "risk_level": purchase.risk_level,
        "days_impacted_predicted": purchase.days_impacted_predicted,
        "liquidity_failure": purchase.liquidity_failure,
        "ai_insight": purchase.ai_insight,
        "status": purchase.status,
        "created_at": purchase.created_at,
    }

    if idempotency_key:
        persist_idempotent_payload(
            db=db,
            endpoint=endpoint_key,
            idempotency_key=idempotency_key,
            payload=PurchaseSchema(**response_payload).model_dump(mode="json"),
            resource_type="purchase",
            resource_id=purchase.id,
        )

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        if idempotency_key:
            replay_payload = get_idempotent_payload(db, endpoint_key, idempotency_key)
            if replay_payload:
                return PurchaseSchema(**replay_payload)
        raise

    db.refresh(purchase)
    return purchase


@router.post("/{purchase_id}/reflect", response_model=ReflectionSchema, status_code=status.HTTP_201_CREATED)
async def submit_reflection(
    purchase_id: str,
    reflection_in: ReflectionCreate,
    db: Session = Depends(dependencies.get_db),
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
):
    """
    Submit a 7-day or 30-day reflection post-mortem.
    Compares the predicted days_impacted against the actual outcome, and calls Gemini
    for an actionable learning insight.
    """
    endpoint_key = f"purchases.reflect:{purchase_id}:{reflection_in.window_days}"
    if idempotency_key:
        replay_payload = get_idempotent_payload(db, endpoint_key, idempotency_key)
        if replay_payload:
            return ReflectionSchema(**replay_payload)

    purchase = db.query(PurchaseModel).filter(PurchaseModel.id == purchase_id).first()
    if not purchase:
        raise HTTPException(status_code=404, detail="Purchase evaluation not found")
        
    # Prevent duplicate reflections for the same window on the same item
    existing = db.query(ReflectionModel).filter(
        ReflectionModel.purchase_id == purchase_id,
        ReflectionModel.window_days == reflection_in.window_days
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail=f"Reflection already exists for {reflection_in.window_days}-day window.")

    # Calculate Error
    error_pct = None
    if reflection_in.actual_days_impacted is not None and purchase.days_impacted_predicted > 0:
        error_pct = (reflection_in.actual_days_impacted - purchase.days_impacted_predicted) / purchase.days_impacted_predicted

    # Generate AI learning insight based on the delta
    reflection_text = await generate_reflection_insight(
        purchase=purchase, 
        reflection=reflection_in, 
        error_pct=error_pct
    )

    db_reflection = ReflectionModel(
        purchase_id=purchase_id,
        user_id=purchase.user_id,
        window_days=reflection_in.window_days,
        triggered_at=datetime.now(timezone.utc),
        felt_financial_pressure=reflection_in.felt_financial_pressure,
        regret_score=reflection_in.regret_score,
        actual_days_impacted=reflection_in.actual_days_impacted,
        prediction_error_pct=error_pct,
        reflection_text=reflection_text
    )
    db.add(db_reflection)
    db.flush()

    response_payload = ReflectionSchema(
        id=db_reflection.id,
        purchase_id=db_reflection.purchase_id,
        user_id=db_reflection.user_id,
        window_days=db_reflection.window_days,
        triggered_at=db_reflection.triggered_at,
        felt_financial_pressure=db_reflection.felt_financial_pressure,
        regret_score=db_reflection.regret_score,
        actual_days_impacted=db_reflection.actual_days_impacted,
        prediction_error_pct=db_reflection.prediction_error_pct,
        reflection_text=db_reflection.reflection_text,
    )

    if idempotency_key:
        persist_idempotent_payload(
            db=db,
            endpoint=endpoint_key,
            idempotency_key=idempotency_key,
            payload=response_payload.model_dump(mode="json"),
            resource_type="reflection",
            resource_id=db_reflection.id,
        )

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        if idempotency_key:
            replay_payload = get_idempotent_payload(db, endpoint_key, idempotency_key)
            if replay_payload:
                return ReflectionSchema(**replay_payload)
        raise

    return response_payload
