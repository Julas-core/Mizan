import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, timezone

from app.db.session import SessionLocal
from app.models.reflection import Purchase, Reflection
from app.services.outbox_worker import process_pending_outbox_events, cleanup_processed_events

logger = logging.getLogger(__name__)

def check_pending_reflections():
    """
    Background job that runs daily.
    Finds purchases that were made exactly 7 or 30 days ago and do not yet have a reflection.
    In a full production app, this would trigger Push Notifications or emails.
    """
    logger.info("Running background job: check_pending_reflections")
    
    db: Session = SessionLocal()
    try:
        now = datetime.now(timezone.utc)
        
        # We look for purchases explicitly marked as "BOUGHT"
        purchases = db.query(Purchase).filter(Purchase.status == "BOUGHT").all()
        
        for p in purchases:
            # Simple calculation for days elapsed
            days_elapsed = (now - p.created_at).days
            
            if days_elapsed >= 7 and days_elapsed < 30:
                # Check if 7-day reflection exists
                existing = db.query(Reflection).filter(
                    Reflection.purchase_id == p.id,
                    Reflection.window_days == 7
                ).first()
                if not existing:
                    logger.info(f"Notification Trigger: User {p.user_id} needs a 7-day reflection for '{p.item_name}'")
                    # Here is where you would call a Firebase/APNS push notification service
                    
            elif days_elapsed >= 30:
                # Check if 30-day reflection exists
                existing = db.query(Reflection).filter(
                    Reflection.purchase_id == p.id,
                    Reflection.window_days == 30
                ).first()
                if not existing:
                    logger.info(f"Notification Trigger: User {p.user_id} needs a 30-day reflection for '{p.item_name}'")
                    # Here is where you would call a Firebase/APNS push notification service

    except Exception as e:
        logger.error(f"Error in check_pending_reflections: {e}")
    finally:
        db.close()

# Create scheduler singleton
scheduler = AsyncIOScheduler()

def start_scheduler():
    """Start the APScheduler background jobs."""
    if scheduler.running:
        logger.info("APScheduler already running")
        return

    # Run every day at 12:00 PM UTC
    scheduler.add_job(
        check_pending_reflections,
        trigger=CronTrigger(hour=12, minute=0),
        id="check_pending_reflections",
        replace_existing=True
    )
    # Also trigger 10 seconds after startup for demonstration/testing purposes
    scheduler.add_job(
        check_pending_reflections,
        trigger="date",
        run_date=datetime.now(timezone.utc) + timedelta(seconds=10),
        id="demo_initial_check",
        replace_existing=True
    )
    scheduler.add_job(
        process_pending_outbox_events,
        trigger="interval",
        seconds=15,
        id="process_pending_outbox_events",
        replace_existing=True,
        max_instances=1,
    )
    # Cleanup processed outbox events daily at 3:00 AM UTC
    scheduler.add_job(
        cleanup_processed_events,
        trigger=CronTrigger(hour=3, minute=0),
        id="cleanup_processed_outbox_events",
        replace_existing=True,
    )
    scheduler.start()
    logger.info("APScheduler started")


def stop_scheduler():
    """Stop APScheduler background jobs."""
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("APScheduler stopped")
