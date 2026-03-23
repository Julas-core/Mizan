from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import date
from app.api import dependencies
from app.api.dependencies import get_current_user, require_same_user
from app.models.user import User as UserModel
from app.schemas.user import User as UserSchema, UserBase, UserSummary
from app.services.decision_engine import (
    EngineIncome, EngineExpense
)

router = APIRouter()
from app.schemas.user import UserCreate

@router.post("/", response_model=UserSchema, status_code=status.HTTP_201_CREATED)
def create_user(user_in: UserCreate, db: Session = Depends(dependencies.get_db)):
    """
    Create a new anonymous user during onboarding.
    Returns the user ID to be stored locally on the device.
    """
    try:
        db_user = UserModel(
            time_to_savings_goal_days=user_in.time_to_savings_goal_days,
            current_balance_cents=user_in.current_balance_cents or 0
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error during user creation: {str(e)}"
        )

@router.patch("/{user_id}", response_model=UserSchema)
def update_user(user_id: str, user_in: UserBase, db: Session = Depends(dependencies.get_db), current_user = Depends(get_current_user)):
    """
    Update a user's settings, like their current balance or savings goal horizon.
    """
    require_same_user(current_user, user_id)
    db_user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
        
    update_data = user_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_user, key, value)
        
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.get("/{user_id}", response_model=UserSchema)
def get_user(user_id: str, db: Session = Depends(dependencies.get_db), current_user = Depends(get_current_user)):
    """
    Get a user by ID.
    """
    require_same_user(current_user, user_id)
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/{user_id}/summary", response_model=UserSummary)
def get_user_summary(user_id: str, db: Session = Depends(dependencies.get_db), current_user = Depends(get_current_user)):
    """
    Get a calculated financial summary for the user.
    """
    require_same_user(current_user, user_id)
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
    
    # Use real actual balance, defaulting to baseline_starting_cash if user hasn't set it yet.
    baseline_starting_cash = int(max(0, projected_monthly_income - projected_monthly_fixed))
    starting_cash = user.current_balance_cents if user.current_balance_cents else baseline_starting_cash

    baseline_incomes = [EngineIncome(**inc.model_dump()) for inc in engine_incomes]
    baseline_timeline = simulate_cashflow_timeline(today, starting_cash, baseline_incomes, engine_expenses)

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
        total_goals_priority_weight=sum(g.priority for g in user.goals),
        current_balance_cents=user.current_balance_cents
    )

from app.schemas.user import UserHabitsInsights
from sqlalchemy import func
from datetime import timedelta
from datetime import datetime, timezone
from app.models.reflection import Purchase as PurchaseModel, Reflection as ReflectionModel

@router.get("/{user_id}/insights", response_model=UserHabitsInsights)
def get_user_insights(user_id: str, db: Session = Depends(dependencies.get_db), current_user = Depends(get_current_user)):
    """
    Get aggregated habits insights for the user.
    """
    require_same_user(current_user, user_id)
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)
    
    # 1. Total bought spend past 30 days
    bought_spend = db.query(func.sum(PurchaseModel.price_cents)).filter(
        PurchaseModel.user_id == user_id,
        PurchaseModel.status == "BOUGHT",
        PurchaseModel.created_at >= thirty_days_ago
    ).scalar() or 0

    # 2. Bought purchases count
    bought_count = db.query(func.count(PurchaseModel.id)).filter(
        PurchaseModel.user_id == user_id,
        PurchaseModel.status == "BOUGHT"
    ).scalar() or 0

    # 3. High regret rate
    reflections = db.query(ReflectionModel.regret_score).filter(
        ReflectionModel.user_id == user_id
    ).all()
    
    high_regret_count = sum(1 for r in reflections if r[0] >= 4)
    total_reflections = len(reflections)
    high_regret_rate_percent = int((high_regret_count / total_reflections * 100)) if total_reflections > 0 else 0

    # 4. Top regret category
    # Find purchases that have reflections with regret >= 4
    top_regret_category = "None"
    top_cat = db.query(
        PurchaseModel.category, func.count(PurchaseModel.category).label('cnt')
    ).join(ReflectionModel, PurchaseModel.id == ReflectionModel.purchase_id).filter(
        PurchaseModel.user_id == user_id,
        ReflectionModel.regret_score >= 4
    ).group_by(PurchaseModel.category).order_by(func.count(PurchaseModel.category).desc()).first()
    
    if top_cat:
        top_regret_category = top_cat[0]

    # 5. Generate dynamic insights via insight_generator
    from app.services.insight_generator import generate_insights
    from app.services.decision_engine import (
        simulate_cashflow_timeline, EngineIncome as EI, EngineExpense as EE
    )

    # Build cashflow timeline for the low-balance insight
    cashflow_timeline = None
    if user.incomes and user.expenses:
        engine_incomes = [
            EI(amount_cents=i.amount_cents, frequency=i.frequency,
               next_paydate=i.next_paydate, confidence_score=i.confidence_score)
            for i in user.incomes
        ]
        engine_expenses = [
            EE(amount_cents=e.amount_cents, is_fixed=e.is_fixed, due_date_day=e.due_date_day)
            for e in user.expenses
        ]
        starting = user.current_balance_cents or 0
        cashflow_timeline = simulate_cashflow_timeline(
            date.today(), starting, engine_incomes, engine_expenses
        )

    dynamic_insights = generate_insights(db, user_id, cashflow_timeline)
    main_trend = dynamic_insights[0] if dynamic_insights else "Keep tracking your spending to unlock insights!"

    # 6. Behavioral score (simple: 100 - regret_rate)
    behavioral_score = max(0, 100 - high_regret_rate_percent)

    return UserHabitsInsights(
        main_behavior_trend=main_trend,
        friday_overspend_percent=0,
        impulse_window=dynamic_insights[2] if len(dynamic_insights) > 2 else "Not enough data yet",
        top_regret_category=top_regret_category,
        high_regret_rate_percent=high_regret_rate_percent,
        bought_purchases_count=bought_count,
        total_bought_spend_last_30d_cents=int(bought_spend),
        behavioral_score=behavioral_score,
    )
