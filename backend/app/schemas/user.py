from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime
from app.schemas.income import Income
from app.schemas.expense import Expense
from app.schemas.goal import Goal

class UserBase(BaseModel):
    time_to_savings_goal_days: Optional[int] = None
    current_balance_cents: Optional[int] = 0

class UserCreate(UserBase):
    pass

class User(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: str
    created_at: datetime
    incomes: List[Income] = []
    expenses: List[Expense] = []
    goals: List[Goal] = []
    current_balance_cents: int = 0
    access_token: Optional[str] = None

class UpcomingBill(BaseModel):
    name: str
    amount_cents: int
    date: str
    days_until: int

class UserSummary(BaseModel):
    safe_to_spend_cents: int
    days_to_next_income: int
    total_monthly_income_cents: int
    total_monthly_fixed_expenses_cents: int
    total_goals_priority_weight: int
    current_balance_cents: int
    days_to_next_bill: int
    next_bill_amount_cents: int
    upcoming_bills: List[UpcomingBill] = []


class UserHabitsInsights(BaseModel):
    main_behavior_trend: str
    friday_overspend_percent: int
    impulse_window: str
    top_regret_category: str
    high_regret_rate_percent: int
    bought_purchases_count: int
    total_bought_spend_last_30d_cents: int
    behavioral_score: int
