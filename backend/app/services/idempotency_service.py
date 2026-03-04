import json
from typing import Any

from sqlalchemy.orm import Session

from app.models.idempotency import IdempotencyKey


def get_idempotent_payload(db: Session, endpoint: str, idempotency_key: str) -> dict[str, Any] | None:
    record = (
        db.query(IdempotencyKey)
        .filter(
            IdempotencyKey.endpoint == endpoint,
            IdempotencyKey.idempotency_key == idempotency_key,
        )
        .first()
    )
    if not record:
        return None
    return json.loads(record.response_json)


def persist_idempotent_payload(
    db: Session,
    endpoint: str,
    idempotency_key: str,
    payload: dict[str, Any],
    resource_type: str | None = None,
    resource_id: str | None = None,
) -> IdempotencyKey:
    record = IdempotencyKey(
        endpoint=endpoint,
        idempotency_key=idempotency_key,
        resource_type=resource_type,
        resource_id=resource_id,
        response_json=json.dumps(payload),
    )
    db.add(record)
    return record
