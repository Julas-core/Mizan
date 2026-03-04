from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import date
from app.api import dependencies
from app.models.user import User as UserModel
from app.schemas.user import User as UserSchema, UserCreate, UserSummary
from app.services.decision_engine import (
    EngineIncome, EngineExpense
)

router = APIRouter()

@router.post("/", response_model=UserSchema, status_code=status.HTTP_201_CREATED)
def create_user(user_in: UserCreate, db: Session = Depends(dependencies.get_db)):
    """
    Create a new user profile.
    """
    db_user = UserModel(time_to_savings_goal_days=user_in.time_to_savings_goal_days)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.get("/{user_id}", response_model=UserSchema)
def get_user(user_id: str, db: Session = Depends(dependencies.get_db)):
    """
    Get a user by ID.
    """
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/{user_id}/summary", response_model=UserSummary)
def get_user_summary(user_id: str, db: Session = Depends(dependencies.get_db)):
    """
    Get a calculated financial summary for the user.
    """
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
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

    # Calculate days to next income
    days_to_next = 30 # Default
    today = date.today()
    for inc in user.incomes:
        delta = (inc.next_paydate - today).days
        if 0 <= delta < days_to_next:
            days_to_next = delta

    # Calculate dynamic weekly capacity using the decision engine's simulation logic
    from app.services.decision_engine import simulate_cashflow_timeline, HORIZON_DAYS, UNCERTAINTY_MARGIN_PCT

    # Derive a baseline starting cash from expected monthly net so we don't
    # under-report safe spend purely because today's balance isn't tracked yet.
    projected_monthly_income = 0
    for inc in engine_incomes:
        if inc.frequency == "Monthly":
            projected_monthly_income += inc.amount_cents * inc.confidence_score
        elif inc.frequency == "Biweekly":
            projected_monthly_income += inc.amount_cents * 2 * inc.confidence_score
        elif inc.frequency == "Weekly":
            projected_monthly_income += inc.amount_cents * 4 * inc.confidence_score
        elif inc.frequency == "One-time":
            projected_monthly_income += inc.amount_cents * inc.confidence_score

    projected_monthly_fixed = sum(exp.amount_cents for exp in engine_expenses if exp.is_fixed)
    baseline_starting_cash = int(max(0, projected_monthly_income - projected_monthly_fixed))

    baseline_incomes = [EngineIncome(**inc.model_dump()) for inc in engine_incomes]
    baseline_timeline = simulate_cashflow_timeline(today, baseline_starting_cash, baseline_incomes, engine_expenses)

    cycle_budget = max(0, baseline_timeline[-1])
    cycle_budget = int(cycle_budget * (1.0 - UNCERTAINTY_MARGIN_PCT))
    daily_safe_capacity = (cycle_budget / HORIZON_DAYS) if cycle_budget > 0 else 0
    weekly_safe_to_spend_cents = int(daily_safe_capacity * 7)
    
    total_monthly_income = sum(inc.amount_cents for inc in user.incomes if inc.frequency == 'Monthly')
    total_monthly_income += sum(inc.amount_cents * 4 for inc in user.incomes if inc.frequency == 'Weekly')

    total_fixed = sum(exp.amount_cents for exp in user.expenses if exp.is_fixed)

    return UserSummary(
        safe_to_spend_cents=weekly_safe_to_spend_cents,
        days_to_next_income=days_to_next,
        total_monthly_income_cents=total_monthly_income,
        total_monthly_fixed_expenses_cents=total_fixed,
        total_goals_priority_weight=sum(g.priority for g in user.goals)
    )
