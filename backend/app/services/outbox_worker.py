import logging
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.models.goal import Goal
from app.models.outbox import EventStatus, OutboxEvent

logger = logging.getLogger(__name__)


def process_pending_outbox_events(batch_size: int = 50) -> int:
    """
    Process a small batch of pending outbox events.

    This runs in the background and applies side effects outside the original
    HTTP request while preserving atomic event creation inside the request
    transaction.
    """
    db: Session = SessionLocal()
    try:
        pending_event_ids = [
            event_id
            for (event_id,) in (
                db.query(OutboxEvent.id)
                .filter(OutboxEvent.status == EventStatus.PENDING)
                .order_by(OutboxEvent.created_at.asc())
                .limit(batch_size)
                .all()
            )
        ]
    finally:
        db.close()

    processed_count = 0
    for event_id in pending_event_ids:
        if process_outbox_event(event_id):
            processed_count += 1

    if processed_count:
        logger.info("Processed %s pending outbox event(s)", processed_count)

    return processed_count


def process_outbox_event(event_id: str) -> bool:
    """Process a single outbox event by id."""
    db: Session = SessionLocal()
    try:
        event = (
            db.query(OutboxEvent)
            .filter(OutboxEvent.id == event_id)
            .first()
        )
        if not event or event.status != EventStatus.PENDING:
            return False

        _dispatch_outbox_event(db, event)
        event.status = EventStatus.PROCESSED
        event.processed_at = datetime.now(timezone.utc)
        db.commit()
        logger.info("Outbox event %s processed: %s", event.id, event.event_type)
        return True
    except Exception:
        db.rollback()
        _mark_event_failed(db, event_id)
        logger.exception("Failed to process outbox event %s", event_id)
        return False
    finally:
        db.close()


def _dispatch_outbox_event(db: Session, event: OutboxEvent) -> None:
    if event.event_type == "PurchaseStatusUpdated":
        _handle_purchase_status_updated(db, event.payload)
        return

    if event.event_type in {"DecisionRecorded", "ReflectionRecorded"}:
        logger.info("Outbox event %s recorded with no async side effects", event.event_type)
        return

    raise ValueError(f"Unsupported outbox event type: {event.event_type}")


def _handle_purchase_status_updated(db: Session, payload: dict) -> None:
    if payload.get("status") != "BOUGHT":
        logger.info("Skipping outbox purchase event because status is %s", payload.get("status"))
        return

    goal_id = payload.get("spent_from_goal_id")
    if not goal_id:
        logger.info("Purchase %s was bought without goal allocation", payload.get("purchase_id"))
        return

    price_cents = int(payload.get("price_cents") or 0)
    user_id = payload.get("user_id")

    goal = db.query(Goal).filter(Goal.id == goal_id).first()
    if not goal:
        raise ValueError(f"Goal {goal_id} not found for purchase event")

    if goal.user_id != user_id:
        raise ValueError(f"Goal {goal_id} does not belong to user {user_id}")

    original_target = goal.target_amount_cents
    goal.target_amount_cents = max(0, original_target - price_cents)
    logger.info(
        "Applied purchase of %s cents against goal %s (%s -> %s)",
        price_cents,
        goal_id,
        original_target,
        goal.target_amount_cents,
    )


def _mark_event_failed(db: Session, event_id: str) -> None:
    event = db.query(OutboxEvent).filter(OutboxEvent.id == event_id).first()
    if not event or event.status != EventStatus.PENDING:
        return

    event.status = EventStatus.FAILED
    db.commit()