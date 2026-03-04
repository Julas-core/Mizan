from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from datetime import date

from app.api import dependencies
from app.models.user import User as UserModel
from app.models.reflection import Purchase as PurchaseModel

from app.schemas.decision import PurchaseEvaluateRequest, PurchaseEvaluateResponse
from app.services.decision_engine import (
    EngineIncome, EngineExpense, EngineGoal, evaluate_purchase
)
from app.services.llm_service import generate_insight
from app.services.idempotency_service import get_idempotent_payload, persist_idempotent_payload

router = APIRouter()

@router.post("/{user_id}/evaluate", response_model=PurchaseEvaluateResponse)
async def evaluate_item(
    user_id: str,
    request: PurchaseEvaluateRequest,
    db: Session = Depends(dependencies.get_db),
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
):
    """
    Evaluates a potential purchase against the user's financial reality.
    Uses pure mathematical pure functions internally to simulate 30-day cashflow horizons.
    """
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    endpoint_key = f"decisions.evaluate:{user_id}"
    if idempotency_key:
        replay_payload = get_idempotent_payload(db, endpoint_key, idempotency_key)
        if replay_payload:
            return PurchaseEvaluateResponse(**replay_payload)
        
    # Map SQLAlchemy ORM models directly to the Engine's Input Models (Pure dependencies)
    engine_incomes = [
        EngineIncome(
            amount_cents=inc.amount_cents,
            frequency=inc.frequency,
            next_paydate=inc.next_paydate,
            confidence_score=inc.confidence_score
        ) for inc in user.incomes
    ]
    
    engine_expenses = [
        EngineExpense(
            amount_cents=exp.amount_cents,
            is_fixed=exp.is_fixed,
            due_date_day=exp.due_date_day
        ) for exp in user.expenses
    ]
    
    engine_goals = [
        EngineGoal(
            id=g.id,
            target_amount_cents=g.target_amount_cents,
            priority=g.priority
        ) for g in user.goals
    ]
    
    # In a full-fledged system, starting cash would be tracked dynamically or via Plaid
    # For this prototype, we'll assume a conservative 0 default if we aren't tracking bank balance.
    starting_cash_cents = 0 
    
    # Run the core algorithmic math evaluation
    evaluation = evaluate_purchase(
        item_price_cents=request.price_cents,
        starting_cash_cents=starting_cash_cents,
        incomes=engine_incomes,
        expenses=engine_expenses,
        goals=engine_goals,
        current_date=date.today()
    )

    # Build goal/expense context for richer LLM prompts
    goals_context = [{"id": g.id, "name": g.name} for g in user.goals]
    expenses_context = [
        {"name": e.name, "amount_cents": e.amount_cents, "due_date_day": e.due_date_day}
        for e in user.expenses if e.is_fixed
    ]

    # Generate human-readable AI insight from Gemini
    insight = await generate_insight(
        item_name=request.item_name,
        item_price_cents=request.price_cents,
        result=evaluation,
        user_goals_context=goals_context,
        upcoming_expenses_context=expenses_context
    )

    # Save to the Database (Phase 4: Reflection Learning setup)
    db_purchase = PurchaseModel(
        user_id=user_id,
        item_name=request.item_name,
        price_cents=request.price_cents,
        category=request.category,
        affordability_score=evaluation.affordability_score,
        risk_level=evaluation.risk_level,
        days_impacted_predicted=evaluation.days_impacted,
        liquidity_failure=evaluation.liquidity_failure,
        ai_insight=insight,
        status="EVALUATED"
    )
    db.add(db_purchase)
    db.flush()

    # Map the algorithm output format to our REST Response Pydantic Schema
    response_payload = PurchaseEvaluateResponse(
        purchase_id=db_purchase.id,
        affordability_score=evaluation.affordability_score,
        risk_level=evaluation.risk_level,
        days_impacted=evaluation.days_impacted,
        liquidity_failure=evaluation.liquidity_failure,
        deficit_mode=evaluation.deficit_mode,
        goals_delayed=evaluation.goals_delayed,
        ai_insight=insight
    )

    if idempotency_key:
        persist_idempotent_payload(
            db=db,
            endpoint=endpoint_key,
            idempotency_key=idempotency_key,
            payload=response_payload.model_dump(),
            resource_type="purchase",
            resource_id=db_purchase.id,
        )

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        if idempotency_key:
            replay_payload = get_idempotent_payload(db, endpoint_key, idempotency_key)
            if replay_payload:
                return PurchaseEvaluateResponse(**replay_payload)
        raise

    return response_payload
