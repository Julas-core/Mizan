from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import date, timedelta
from app.api import dependencies
from app.models.user import User as UserModel
from app.schemas.user import User as UserSchema, UserCreate, UserSummary
from app.services.decision_engine import (
    EngineIncome, EngineExpense, evaluate_purchase
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
    days_to_next = 99 # Default
    today = date.today()
    for inc in user.incomes:
        delta = (inc.next_paydate - today).days
        if 0 <= delta < days_to_next:
            days_to_next = delta

    # Run a mock 0-cent evaluation to get the engine's safe_to_spend_cents (daily_safe_capacity)
    evaluation = evaluate_purchase(
        item_price_cents=0,
        starting_cash_cents=0,
        incomes=engine_incomes,
        expenses=engine_expenses,
        goals=[], # simplified for summary
        current_date=today
    )

    # We'll return "Weekly Safe-to-Spend" as it's common in finance apps
    # Based on engine's internal Daily Capacity
    # Note: cycle_budget calculation is internal to evaluate_purchase
    # We'll approximate safe_to_spend per week
    
    total_monthly_income = sum(inc.amount_cents for inc in user.incomes if inc.frequency == 'Monthly')
    total_monthly_income += sum(inc.amount_cents * 4 for inc in user.incomes if inc.frequency == 'Weekly')
    
    total_fixed = sum(exp.amount_cents for exp in user.expenses if exp.is_fixed)

    return UserSummary(
        safe_to_spend_cents=int((total_monthly_income - total_fixed) / 4), # weekly
        days_to_next_income=days_to_next,
        total_monthly_income_cents=total_monthly_income,
        total_monthly_fixed_expenses_cents=total_fixed,
        total_goals_priority_weight=sum(g.priority for g in user.goals)
    )
