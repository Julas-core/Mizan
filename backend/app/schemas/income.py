from pydantic import BaseModel, ConfigDict, Field
from typing import Literal
from datetime import date

class IncomeBase(BaseModel):
    amount_cents: int = Field(..., ge=1)
    frequency: Literal["weekly", "biweekly", "monthly", "one_time"] = "monthly"
    next_paydate: date
    confidence_score: float = Field(1.0, ge=0.0, le=1.0)

class IncomeCreate(IncomeBase):
    pass

class Income(IncomeBase):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
