from pydantic import BaseModel, ConfigDict, Field
from typing import Optional

class ExpenseBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    amount_cents: int = Field(..., ge=1)
    is_fixed: bool = True
    due_date_day: Optional[int] = Field(None, ge=1, le=31)

class ExpenseCreate(ExpenseBase):
    pass

class Expense(ExpenseBase):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
