from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api import dependencies
from app.models.reflection import Purchase as PurchaseModel, Reflection as ReflectionModel
from app.schemas.reflection import PurchaseUpdateStatus, Purchase as PurchaseSchema, ReflectionCreate, Reflection as ReflectionSchema
from app.services.llm_service import generate_reflection_insight

router = APIRouter()

@router.patch("/{purchase_id}/status", response_model=PurchaseSchema)
def update_purchase_status(purchase_id: str, status_update: PurchaseUpdateStatus, db: Session = Depends(dependencies.get_db)):
    """
    Updates the outcome of an evaluated purchase.
    Valid statuses: BOUGHT, ABANDONED
    """
    valid_statuses = {"BOUGHT", "ABANDONED"}
    if status_update.status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {valid_statuses}")

    purchase = db.query(PurchaseModel).filter(PurchaseModel.id == purchase_id).first()
    if not purchase:
        raise HTTPException(status_code=404, detail="Purchase evaluation not found")

    purchase.status = status_update.status
    db.commit()
    db.refresh(purchase)
    return purchase


@router.post("/{purchase_id}/reflect", response_model=ReflectionSchema, status_code=status.HTTP_201_CREATED)
async def submit_reflection(purchase_id: str, reflection_in: ReflectionCreate, db: Session = Depends(dependencies.get_db)):
    """
    Submit a 7-day or 30-day reflection post-mortem.
    Compares the predicted days_impacted against the actual outcome, and calls Gemini
    for an actionable learning insight.
    """
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
        felt_financial_pressure=reflection_in.felt_financial_pressure,
        regret_score=reflection_in.regret_score,
        actual_days_impacted=reflection_in.actual_days_impacted,
        prediction_error_pct=error_pct,
        reflection_text=reflection_text
    )
    db.add(db_reflection)
    db.commit()
    db.refresh(db_reflection)
    
    return db_reflection
