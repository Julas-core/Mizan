from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.base_class import Base, generate_uuid

class Purchase(Base):
    """
    Records every item the user evaluates. Created when the user runs a decision analysis.
    Status updates as the user acts on the decision.
    """
    __tablename__ = "purchases"

    id = Column(String, primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)

    # What was evaluated
    item_name = Column(String, nullable=False)
    price_cents = Column(Integer, nullable=False)
    category = Column(String, nullable=True)

    # Engine output at time of evaluation
    affordability_score = Column(Integer, nullable=False)
    risk_level = Column(String, nullable=False)
    days_impacted_predicted = Column(Float, nullable=False)
    liquidity_failure = Column(Boolean, nullable=False, default=False)

    # AI insight at time of evaluation
    ai_insight = Column(Text, nullable=True)

    # User decision
    status = Column(String, nullable=False, default="EVALUATED")  # EVALUATED, BOUGHT, ABANDONED

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="purchases")
    reflections = relationship("Reflection", back_populates="purchase", cascade="all, delete-orphan")


class Reflection(Base):
    """
    Post-mortem record comparing the engine's predicted impact vs the user's actual
    financial experience after 7 or 30 days.
    """
    __tablename__ = "reflections"

    id = Column(String, primary_key=True, default=generate_uuid, index=True)
    purchase_id = Column(String, ForeignKey("purchases.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)

    # Reflection window
    window_days = Column(Integer, nullable=False)  # 7 or 30
    triggered_at = Column(DateTime(timezone=True), server_default=func.now())

    # User's self-reported financial outcome (optional but powerful for learning)
    felt_financial_pressure = Column(Boolean, nullable=True)
    regret_score = Column(Integer, nullable=True)  # 1-5, how much user regrets the purchase

    # Computed deviation: did reality match the model?
    actual_days_impacted = Column(Float, nullable=True)
    prediction_error_pct = Column(Float,  nullable=True)  # (actual - predicted) / predicted

    # AI insight on what happened vs what was predicted
    reflection_text = Column(Text, nullable=True)

    # Relationships
    purchase = relationship("Purchase", back_populates="reflections")
