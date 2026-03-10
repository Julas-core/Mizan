from pydantic import BaseModel, ConfigDict
from datetime import date

class IncomeBase(BaseModel):
    amount_cents: int
    frequency: str
    next_paydate: date
    confidence_score: float = 1.0

class IncomeCreate(IncomeBase):
    pass

class Income(IncomeBase):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
