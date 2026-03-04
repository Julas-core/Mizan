from sqlalchemy import Column, String, DateTime, Text, UniqueConstraint
from sqlalchemy.sql import func

from app.db.base_class import Base, generate_uuid


class IdempotencyKey(Base):
    __tablename__ = "idempotency_keys"
    __table_args__ = (
        UniqueConstraint("endpoint", "idempotency_key", name="uq_idempotency_endpoint_key"),
    )

    id = Column(String, primary_key=True, default=generate_uuid, index=True)
    endpoint = Column(String, nullable=False)
    idempotency_key = Column(String, nullable=False)
    resource_type = Column(String, nullable=True)
    resource_id = Column(String, nullable=True)
    response_json = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
