from pydantic import BaseModel, ConfigDict, Field
from typing import Optional, List, Literal
from datetime import datetime

# --- Purchase Schemas ---

class PurchaseBase(BaseModel):
    item_name: str = Field(..., min_length=1, max_length=255)
    price_cents: int = Field(..., ge=1)
    category: Optional[str] = Field("General", max_length=100)

class PurchaseCreate(PurchaseBase):
    affordability_score: int = Field(..., ge=0, le=100)
    risk_level: Literal["LOW", "MEDIUM", "HIGH", "CRITICAL"]
    days_impacted_predicted: float = Field(..., ge=0)
    liquidity_failure: bool
    ai_insight: Optional[str] = None
    status: Literal["EVALUATED", "BOUGHT", "ABANDONED"] = "EVALUATED"

class PurchaseUpdateStatus(BaseModel):
    status: Literal["BOUGHT", "ABANDONED"]
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
    window_days: Literal[7, 30]

class ReflectionCreate(ReflectionBase):
    purchase_id: str
    felt_financial_pressure: Optional[bool] = None
    regret_score: Optional[int] = Field(None, ge=1, le=5)
    actual_days_impacted: Optional[float] = Field(None, ge=0)
    prediction_error_pct: Optional[float] = None
    reflection_text: Optional[str] = Field(None, max_length=2000)

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
