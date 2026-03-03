from sqlalchemy import Column, String, Integer, ForeignKey
from sqlalchemy.orm import relationship

from app.db.base_class import Base, generate_uuid

class Goal(Base):
    __tablename__ = "goals"

    id = Column(String, primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    
    name = Column(String, nullable=False) # e.g. "New Keyboard"
    target_amount_cents = Column(Integer, nullable=False)
    priority = Column(Integer, nullable=False, default=1) # 1 = Highest Priority
    image_url = Column(String, nullable=True) # Optional photo

    # Relationship back to User
    user = relationship("User", back_populates="goals")
