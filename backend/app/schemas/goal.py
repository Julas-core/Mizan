from pydantic import BaseModel, ConfigDict
from typing import Optional

class GoalBase(BaseModel):
    name: str
    target_amount_cents: int
    priority: int = 1 # 1 = Highest Priority
    image_url: Optional[str] = None

class GoalCreate(GoalBase):
    pass

class Goal(GoalBase):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
