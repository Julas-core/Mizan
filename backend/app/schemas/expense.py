from pydantic import BaseModel
from typing import Optional

class ExpenseBase(BaseModel):
    name: str
    amount_cents: int
    is_fixed: bool = True
    due_date_day: Optional[int] = None

class ExpenseCreate(ExpenseBase):
    pass

class Expense(ExpenseBase):
    id: str
    user_id: str

    class Config:
        orm_mode = True
