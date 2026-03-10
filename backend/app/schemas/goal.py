from pydantic import BaseModel, ConfigDict, Field
from typing import Optional

class GoalBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    target_amount_cents: int = Field(..., ge=1)
    priority: int = Field(1, ge=1, le=10)
    image_url: Optional[str] = Field(None, max_length=2048)

class GoalCreate(GoalBase):
    pass

class Goal(GoalBase):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
