import os
import sys

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.db import base  # noqa: F401
from app.db.base_class import Base
from app.models.goal import Goal
from app.models.outbox import EventStatus, OutboxEvent
from app.models.user import User
from app.services import outbox_worker


@pytest.fixture
def test_session_factory(tmp_path, monkeypatch):
    db_file = tmp_path / "outbox_worker_test.db"
    engine = create_engine(
        f"sqlite:///{db_file}",
        connect_args={"check_same_thread": False},
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)
    monkeypatch.setattr(outbox_worker, "SessionLocal", TestingSessionLocal)

    yield TestingSessionLocal

    Base.metadata.drop_all(bind=engine)
    engine.dispose()


def test_process_purchase_status_event_reduces_goal_balance(test_session_factory):
    db = test_session_factory()
    user = User()
    db.add(user)
    db.flush()

    goal = Goal(user_id=user.id, name="Emergency Laptop", target_amount_cents=100_000, priority=1)
    db.add(goal)
    db.flush()

    event = OutboxEvent(
        event_type="PurchaseStatusUpdated",
        payload={
            "purchase_id": "purchase-1",
            "user_id": user.id,
            "status": "BOUGHT",
            "price_cents": 25_000,
            "spent_from_goal_id": goal.id,
        },
    )
    db.add(event)
    db.commit()
    goal_id = goal.id
    event_id = event.id
    db.close()

    processed_count = outbox_worker.process_pending_outbox_events()

    assert processed_count == 1

    verification_db = test_session_factory()
    updated_goal = verification_db.query(Goal).filter(Goal.id == goal_id).first()
    updated_event = verification_db.query(OutboxEvent).filter(OutboxEvent.id == event_id).first()

    assert updated_goal.target_amount_cents == 75_000
    assert updated_event.status == EventStatus.PROCESSED
    assert updated_event.processed_at is not None
    verification_db.close()


def test_process_missing_goal_marks_event_failed(test_session_factory):
    db = test_session_factory()
    user = User()
    db.add(user)
    db.flush()

    event = OutboxEvent(
        event_type="PurchaseStatusUpdated",
        payload={
            "purchase_id": "purchase-2",
            "user_id": user.id,
            "status": "BOUGHT",
            "price_cents": 10_000,
            "spent_from_goal_id": "missing-goal",
        },
    )
    db.add(event)
    db.commit()
    event_id = event.id
    db.close()

    processed_count = outbox_worker.process_pending_outbox_events()

    assert processed_count == 0

    verification_db = test_session_factory()
    updated_event = verification_db.query(OutboxEvent).filter(OutboxEvent.id == event_id).first()

    assert updated_event.status == EventStatus.FAILED
    assert updated_event.processed_at is None
    verification_db.close()