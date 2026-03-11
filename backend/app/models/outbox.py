import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Enum, JSON, Integer
from app.db.base_class import Base
import enum

class EventStatus(str, enum.Enum):
    PENDING = "PENDING"
    PROCESSED = "PROCESSED"
    FAILED = "FAILED"

class OutboxEvent(Base):
    __tablename__ = "outbox_events"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    event_type = Column(String, index=True, nullable=False)
    payload = Column(JSON, nullable=False)
    status = Column(Enum(EventStatus), default=EventStatus.PENDING, index=True, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    processed_at = Column(DateTime(timezone=True), nullable=True)
    retries = Column(Integer, default=0, nullable=False)
    next_retry_at = Column(DateTime(timezone=True), nullable=True)
