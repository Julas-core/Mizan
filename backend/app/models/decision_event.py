from sqlalchemy import Boolean, Column, DateTime, ForeignKey, JSON, String
from sqlalchemy.sql import func

from app.db.base_class import Base, generate_uuid


class DecisionEvent(Base):
    __tablename__ = "decision_events"

    id = Column(String, primary_key=True, default=generate_uuid, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    purchase_id = Column(String, ForeignKey("purchases.id"), nullable=True, index=True)

    event_type = Column(String, nullable=False, index=True)
    verdict = Column(String, nullable=True, index=True)
    dominant_factor = Column(String, nullable=True, index=True)
    risk_level = Column(String, nullable=True)
    category = Column(String, nullable=True)
    amount_band = Column(String, nullable=True)
    recommended_action = Column(String, nullable=True)
    user_action = Column(String, nullable=True)
    overrode_recommendation = Column(Boolean, nullable=True)
    feedback_helpful = Column(Boolean, nullable=True)
    metadata_json = Column(JSON, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
