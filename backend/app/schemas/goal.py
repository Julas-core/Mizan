from pydantic import BaseModel
from typing import Optional

class GoalBase(BaseModel):
    name: str
    target_amount_cents: int
    priority: int = 1 # 1 = Highest Priority
    image_url: Optional[str] = None

class GoalCreate(GoalBase):
    pass

class Goal(GoalBase):
    id: str
    user_id: str

    class Config:
        orm_mode = True
