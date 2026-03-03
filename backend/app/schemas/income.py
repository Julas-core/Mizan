from pydantic import BaseModel
from datetime import date

class IncomeBase(BaseModel):
    amount_cents: int
    frequency: str
    next_paydate: date
    confidence_score: float = 1.0

class IncomeCreate(IncomeBase):
    pass

class Income(IncomeBase):
    id: str
    user_id: str

    class Config:
        orm_mode = True
