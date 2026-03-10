from pydantic import BaseModel, ConfigDict
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
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    affordability_score: int
    risk_level: str
    days_impacted_predicted: float
    liquidity_failure: bool
    ai_insight: Optional[str] = None
    status: str
    created_at: datetime

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
    model_config = ConfigDict(from_attributes=True)

    id: str
    purchase_id: str
    user_id: str
    triggered_at: datetime
    felt_financial_pressure: Optional[bool] = None
    regret_score: Optional[int] = None
    actual_days_impacted: Optional[float] = None
    prediction_error_pct: Optional[float] = None
    reflection_text: Optional[str] = None
