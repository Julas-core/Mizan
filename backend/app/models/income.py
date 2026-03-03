from sqlalchemy import Column, String, Float, Date, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base_class import Base, generate_uuid

class Income(Base):
    __tablename__ = "incomes"

    id = Column(String, primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    
    amount_cents = Column(Integer, nullable=False)
    frequency = Column(String, nullable=False) # e.g. "Monthly", "Weekly"
    next_paydate = Column(Date, nullable=False)
    confidence_score = Column(Float, nullable=False, default=1.0) # 0.0 to 1.0

    # Relationship back to User
    user = relationship("User", back_populates="incomes")
