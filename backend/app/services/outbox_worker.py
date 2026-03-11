import logging
from datetime import datetime, timezone, timedelta

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
                .filter(
                    OutboxEvent.status == EventStatus.PENDING,
                    (OutboxEvent.next_retry_at == None) | (OutboxEvent.next_retry_at <= datetime.now(timezone.utc))
                )
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
        _mark_event_failed_or_retry(db, event_id)
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


def _mark_event_failed_or_retry(db: Session, event_id: str) -> None:
    event = db.query(OutboxEvent).filter(OutboxEvent.id == event_id).first()
    if not event or event.status != EventStatus.PENDING:
        return

    event.retries += 1
    if event.retries >= 3:
        event.status = EventStatus.FAILED
        logger.error("Outbox event %s max retries reached. Marked as FAILED.", event_id)
    else:
        # Exponential backoff: 1 min, then 5 mins, then max out
        backoff_minutes = 5 ** (event.retries - 1)
        event.next_retry_at = datetime.now(timezone.utc) + timedelta(minutes=backoff_minutes)
        logger.warning(
            "Outbox event %s failed. Retry %s/3 scheduled at %s", 
            event_id, event.retries, event.next_retry_at
        )

    db.commit()


def cleanup_processed_events() -> int:
    """
    Deletes events that were processed more than 30 days ago.
    """
    db: Session = SessionLocal()
    try:
        thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)
        deleted_count = db.query(OutboxEvent).filter(
            OutboxEvent.status == EventStatus.PROCESSED,
            OutboxEvent.processed_at < thirty_days_ago
        ).delete(synchronize_session=False)
        db.commit()
        if deleted_count > 0:
            logger.info("Cleaned up %s old processed outbox events", deleted_count)
        return deleted_count
    except Exception:
        db.rollback()
        logger.exception("Failed to clean up outbox events")
        return 0
    finally:
        db.close()