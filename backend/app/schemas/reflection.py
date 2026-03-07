from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

# --- Purchase Schemas ---

class PurchaseBase(BaseModel):
    item_name: str
    price_cents: int
    category: Optional[str] = "General"

class PurchaseCreate(PurchaseBase):
    affordability_score: int
    risk_level: str
    days_impacted_predicted: float
    liquidity_failure: bool
    ai_insight: Optional[str] = None
    status: str = "EVALUATED"

class PurchaseUpdateStatus(BaseModel):
    status: str  # e.g., "BOUGHT", "ABANDONED"
    spent_from_goal_id: Optional[str] = None

class Purchase(PurchaseBase):
    id: str
    user_id: str
    affordability_score: int
    risk_level: str
    days_impacted_predicted: float
    liquidity_failure: bool
    ai_insight: Optional[str] = None
    status: str
    created_at: datetime

    class Config:
        orm_mode = True

# --- Reflection Schemas ---

class ReflectionBase(BaseModel):
    window_days: int # 7 or 30

class ReflectionCreate(ReflectionBase):
    purchase_id: str
    felt_financial_pressure: Optional[bool] = None
    regret_score: Optional[int] = None # 1-5
    actual_days_impacted: Optional[float] = None
    prediction_error_pct: Optional[float] = None
    reflection_text: Optional[str] = None

class Reflection(ReflectionBase):
    id: str
    purchase_id: str
    user_id: str
    triggered_at: datetime
    felt_financial_pressure: Optional[bool] = None
    regret_score: Optional[int] = None
    actual_days_impacted: Optional[float] = None
    prediction_error_pct: Optional[float] = None
    reflection_text: Optional[str] = None

    class Config:
        orm_mode = True
