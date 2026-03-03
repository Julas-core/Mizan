from sqlalchemy import Column, String, Integer, Boolean, ForeignKey
from sqlalchemy.orm import relationship

from app.db.base_class import Base, generate_uuid

class Expense(Base):
    __tablename__ = "expenses"

    id = Column(String, primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    
    name = Column(String, nullable=False) # e.g. "Rent", "Estimated Groceries"
    amount_cents = Column(Integer, nullable=False)
    is_fixed = Column(Boolean, nullable=False, default=True)
    due_date_day = Column(Integer, nullable=True) # 1-31, optional

    # Relationship back to User
    user = relationship("User", back_populates="expenses")
