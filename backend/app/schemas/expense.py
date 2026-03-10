from pydantic import BaseModel, ConfigDict
from typing import Optional

class ExpenseBase(BaseModel):
    name: str
    amount_cents: int
    is_fixed: bool = True
    due_date_day: Optional[int] = None

class ExpenseCreate(ExpenseBase):
    pass

class Expense(ExpenseBase):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
