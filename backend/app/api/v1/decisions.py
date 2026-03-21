from fastapi import APIRouter, Depends, HTTPException, Header, Request
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from datetime import date

from app.api import dependencies
from app.api.dependencies import get_current_user, require_same_user
from app.core.config import settings
from app.core.rate_limit import limiter
from app.models.user import User as UserModel
from app.models.reflection import Purchase as PurchaseModel
from app.models.outbox import OutboxEvent

from app.schemas.decision import PurchaseEvaluateRequest, PurchaseEvaluateResponse
from app.services.decision_engine import (
    EngineIncome, EngineExpense, EngineGoal, evaluate_purchase
)
from app.services.llm_service import generate_insight
from app.services.idempotency_service import get_idempotent_payload, persist_idempotent_payload
from app.services.regret_tracker import get_category_regret_rate
from app.services.risk_model import compute_behavior_penalty
from app.services.decision_logger import log_evaluation

router = APIRouter()

@router.post("/{user_id}/evaluate", response_model=PurchaseEvaluateResponse)
@limiter.limit("10/minute")
async def evaluate_item(
    request: Request,
    user_id: str,
    payload: PurchaseEvaluateRequest,
    db: Session = Depends(dependencies.get_db),
    current_user = Depends(get_current_user),
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
):
    """
    Evaluates a potential purchase against the user's financial reality.
    Uses pure mathematical pure functions internally to simulate 30-day cashflow horizons.
    """
    require_same_user(current_user, user_id)
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
    starting_cash_cents = user.current_balance_cents or 0

    # --- Regret Learning ---
    regret_rate = get_category_regret_rate(db, user_id, payload.category)
    behavior_penalty = compute_behavior_penalty(
        regret_rate=regret_rate,
        threshold=0.5,
        max_penalty=settings.MAX_BEHAVIOR_PENALTY,
    )
    behavior_explanation = ""
    if behavior_penalty > 0:
        pct = int(regret_rate * 100)
        behavior_explanation = f"You've regretted similar {payload.category} purchases before ({pct}% regret rate)."

    # Run the core evaluation with composite risk model
    evaluation = evaluate_purchase(
        item_price_cents=payload.price_cents,
        starting_cash_cents=starting_cash_cents,
        incomes=engine_incomes,
        expenses=engine_expenses,
        goals=engine_goals,
        current_date=date.today(),
        behavior_penalty=behavior_penalty,
        behavior_explanation=behavior_explanation,
        risk_weights=(settings.RISK_W_AFFORD, settings.RISK_W_BEHAVE, settings.RISK_W_GOAL),
        max_behavior_penalty=settings.MAX_BEHAVIOR_PENALTY,
        min_goal_window_days=settings.MIN_GOAL_WINDOW_DAYS,
    )

    # Build goal/expense context for richer LLM prompts
    goals_context = [{"id": g.id, "name": g.name} for g in user.goals]
    expenses_context = [
        {"name": e.name, "amount_cents": e.amount_cents, "due_date_day": e.due_date_day}
        for e in user.expenses if e.is_fixed
    ]

    # Generate human-readable AI insight from Gemini
    insight = await generate_insight(
        item_name=payload.item_name,
        item_price_cents=payload.price_cents,
        result=evaluation,
        user_goals_context=goals_context,
        upcoming_expenses_context=expenses_context
    )

    # Save to the Database (Phase 4: Reflection Learning setup)
    db_purchase = PurchaseModel(
        user_id=user_id,
        item_name=payload.item_name,
        price_cents=payload.price_cents,
        category=payload.category,
        affordability_score=evaluation.affordability_score,
        risk_level=evaluation.risk_level,
        days_impacted_predicted=evaluation.days_impacted,
        liquidity_failure=evaluation.liquidity_failure,
        ai_insight=insight,
        status="EVALUATED"
    )
    db.add(db_purchase)
    db.flush()

    outbox_event = OutboxEvent(
        event_type="DecisionRecorded",
        payload={
            "purchase_id": db_purchase.id,
            "user_id": user_id,
            "item_name": db_purchase.item_name,
            "price_cents": db_purchase.price_cents,
            "affordability_score": db_purchase.affordability_score,
            "status": db_purchase.status
        }
    )
    db.add(outbox_event)

    # Map the algorithm output format to our REST Response Pydantic Schema
    response_payload = PurchaseEvaluateResponse(
        purchase_id=db_purchase.id,
        affordability_score=evaluation.affordability_score,
        risk_level=evaluation.risk_level,
        days_impacted=evaluation.days_impacted,
        liquidity_failure=evaluation.liquidity_failure,
        deficit_mode=evaluation.deficit_mode,
        goals_delayed=evaluation.goals_delayed,
        goal_delay_days=evaluation.goal_delay_days,
        risk_breakdown=evaluation.risk_breakdown,
        behavior_penalty=evaluation.behavior_penalty,
        behavior_explanation=evaluation.behavior_explanation,
        ai_insight=insight
    )

    # --- Decision Audit Log ---
    budget_pressure = evaluation.risk_breakdown.get("affordability", 0)
    goal_impact = evaluation.risk_breakdown.get("goal_impact", 0)
    log_evaluation(
        user_id=user_id,
        item_name=payload.item_name,
        price_cents=payload.price_cents,
        category=payload.category,
        budget_pressure=budget_pressure,
        behavior_penalty=behavior_penalty,
        goal_delay_impact=goal_impact,
        regret_rate=regret_rate,
        final_risk_score=evaluation.risk_breakdown.get("final_score", 0),
        risk_level=evaluation.risk_level,
        affordability_score=evaluation.affordability_score,
        goal_delays=evaluation.goal_delay_days,
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
