import pytest
from datetime import date, timedelta, datetime, timezone
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.api.dependencies import get_db
from app.db.base_class import Base
from app.models.user import User
from app.models.goal import Goal
from app.models.reflection import Purchase, Reflection
from app.models.income import Income
from app.models.expense import Expense
from app.core.security import create_access_token

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_api.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)

def create_test_user(db, email="test@example.com"):
    user = User(email=email, hashed_password="hashed_password", current_balance_cents=100000) # $1000
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def get_token(user):
    return create_access_token(user_id=user.id, email=user.email)

def test_get_user_summary():
    db = TestingSessionLocal()
    user = create_test_user(db)
    token = get_token(user)
    
    response = client.get(
        f"/api/v1/users/{user.id}/summary",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["current_balance_cents"] == 100000
    db.close()

def test_patch_user_balance():
    db = TestingSessionLocal()
    user = create_test_user(db)
    token = get_token(user)
    
    response = client.patch(
        f"/api/v1/users/{user.id}",
        json={"current_balance_cents": 50000},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert response.json()["current_balance_cents"] == 50000
    
    # Verify DB update
    db.refresh(user)
    assert user.current_balance_cents == 50000
    db.close()

def test_get_user_insights():
    db = TestingSessionLocal()
    user = create_test_user(db)
    token = get_token(user)
    
    # Create some mock data for insights
    p1 = Purchase(user_id=user.id, item_name="Coffee", price_cents=500, category="Food", status="BOUGHT", 
                  affordability_score=90, risk_level="LOW", days_impacted_predicted=0.5)
    p2 = Purchase(user_id=user.id, item_name="Phone", price_cents=80000, category="Tech", status="ABANDONED",
                  affordability_score=20, risk_level="HIGH", days_impacted_predicted=5.0)
    db.add_all([p1, p2])
    db.commit()
    
    response = client.get(
        f"/api/v1/users/{user.id}/insights",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["bought_purchases_count"] == 1
    assert data["total_bought_spend_last_30d_cents"] == 500
    
    # Check new dynamic fields
    assert "top_regret_category" in data
    assert "behavioral_score" in data
    assert "high_regret_rate_percent" in data
    
    db.close()

def test_evaluate_purchase_endpoint():
    db = TestingSessionLocal()
    user = create_test_user(db)
    token = get_token(user)
    
    # Needs income/expenses so it doesn't fail at Deficit Mode
    inc = Income(user_id=user.id, amount_cents=500000, frequency="Monthly", next_paydate=date.today())
    exp = Expense(user_id=user.id, amount_cents=50000, name="Rent", is_fixed=True, due_date_day=1)
    db.add_all([inc, exp])
    db.commit()

    # Payload for evaluate
    payload = {
        "item_name": "New Laptop",
        "price_cents": 15000,
        "category": "Electronics"
    }
    
    response = client.post(
        f"/api/v1/decisions/{user.id}/evaluate",
        json=payload,
        headers={"Authorization": f"Bearer {token}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert "purchase_id" in data
    assert "affordability_score" in data
    assert "risk_level" in data
    assert "goal_delay_days" in data
    assert "risk_breakdown" in data
    assert "behavior_penalty" in data
    
    # Specific breakdown shape check
    bd = data["risk_breakdown"]
    assert "affordability" in bd
    assert "behavior" in bd
    assert "goal_impact" in bd
    assert "final_score" in bd
    
    db.close()

def test_goals_pagination():
    db = TestingSessionLocal()
    user = create_test_user(db)
    token = get_token(user)
    
    # Create 5 goals (priority 1-5)
    for i in range(1, 6):
        g = Goal(user_id=user.id, name=f"Goal {i}", target_amount_cents=1000, priority=i)
        db.add(g)
    db.commit()
    
    # Test limit=2
    response = client.get(
        f"/api/v1/onboarding/{user.id}/goals?limit=2",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert len(response.json()) == 2
    
    # Test skip=2, limit=2
    response = client.get(
        f"/api/v1/onboarding/{user.id}/goals?skip=2&limit=2",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["name"] == "Goal 3"
    db.close()

def test_history_pagination():
    db = TestingSessionLocal()
    user = create_test_user(db)
    token = get_token(user)
    
    # Create 5 abandoned purchases
    for i in range(5):
        p = Purchase(user_id=user.id, item_name=f"Item {i}", price_cents=100, category="Misc", status="ABANDONED",
                     affordability_score=50, risk_level="MEDIUM", days_impacted_predicted=1.0)
        db.add(p)
    db.commit()
    
    # Test limit=3
    response = client.get(
        f"/api/v1/purchases/{user.id}/history?limit=3",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert len(response.json()) == 3
    db.close()

def test_evaluate_requires_auth():
    payload = {
        "item_name": "New Laptop",
        "price_cents": 150000,
        "category": "Electronics"
    }
    response = client.post("/api/v1/decisions/some-user-id/evaluate", json=payload)
    assert response.status_code == 401


def test_post_decision_event_verdict_shown():
    db = TestingSessionLocal()
    user = create_test_user(db)
    token = get_token(user)

    response = client.post(
        f"/api/v1/analytics/{user.id}/decision-events",
        json={
            "event_type": "verdict_shown",
            "verdict": "Delay",
            "dominant_factor": "behavior",
            "recommended_action": "delay",
            "amount_band": "26-100",
        },
        headers={"Authorization": f"Bearer {token}", "Idempotency-Key": "evt-1"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["event_type"] == "verdict_shown"
    assert data["verdict"] == "Delay"
    assert data["dominant_factor"] == "behavior"
    db.close()


def test_post_decision_event_action_selected():
    db = TestingSessionLocal()
    user = create_test_user(db)
    token = get_token(user)

    purchase = Purchase(
        user_id=user.id,
        item_name="Headphones",
        price_cents=12000,
        category="Tech",
        status="EVALUATED",
        affordability_score=70,
        risk_level="MEDIUM",
        days_impacted_predicted=2.0,
    )
    db.add(purchase)
    db.commit()
    db.refresh(purchase)

    response = client.post(
        f"/api/v1/analytics/{user.id}/decision-events",
        json={
            "event_type": "action_selected",
            "purchase_id": purchase.id,
            "verdict": "Delay",
            "dominant_factor": "goal_impact",
            "recommended_action": "delay",
            "user_action": "bought",
            "overrode_recommendation": True,
        },
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["event_type"] == "action_selected"
    assert data["purchase_id"] == purchase.id
    assert data["overrode_recommendation"] is True
    db.close()


def test_decision_quality_summary_rates():
    db = TestingSessionLocal()
    user = create_test_user(db)
    token = get_token(user)

    purchase_follow = Purchase(
        user_id=user.id,
        item_name="Lamp",
        price_cents=3000,
        category="Home",
        status="ABANDONED",
        affordability_score=85,
        risk_level="LOW",
        days_impacted_predicted=0.2,
    )
    purchase_override = Purchase(
        user_id=user.id,
        item_name="Console",
        price_cents=50000,
        category="Gaming",
        status="BOUGHT",
        affordability_score=35,
        risk_level="HIGH",
        days_impacted_predicted=7.0,
    )
    db.add_all([purchase_follow, purchase_override])
    db.commit()
    db.refresh(purchase_follow)
    db.refresh(purchase_override)

    # verdict shown x2
    for payload in [
        {
            "event_type": "verdict_shown",
            "purchase_id": purchase_follow.id,
            "verdict": "Delay",
            "dominant_factor": "behavior",
            "recommended_action": "delay",
        },
        {
            "event_type": "verdict_shown",
            "purchase_id": purchase_override.id,
            "verdict": "Avoid",
            "dominant_factor": "affordability",
            "recommended_action": "avoid",
        },
    ]:
        r = client.post(
            f"/api/v1/analytics/{user.id}/decision-events",
            json=payload,
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 200

    # one accepted, one overridden
    for payload in [
        {
            "event_type": "action_selected",
            "purchase_id": purchase_follow.id,
            "verdict": "Delay",
            "dominant_factor": "behavior",
            "recommended_action": "delay",
            "user_action": "abandoned",
            "overrode_recommendation": False,
        },
        {
            "event_type": "action_selected",
            "purchase_id": purchase_override.id,
            "verdict": "Avoid",
            "dominant_factor": "affordability",
            "recommended_action": "avoid",
            "user_action": "bought",
            "overrode_recommendation": True,
        },
    ]:
        r = client.post(
            f"/api/v1/analytics/{user.id}/decision-events",
            json=payload,
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 200

    # feedback helpful once
    r = client.post(
        f"/api/v1/analytics/{user.id}/decision-events",
        json={
            "event_type": "feedback_submitted",
            "purchase_id": purchase_follow.id,
            "feedback_helpful": True,
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200

    # reflections to compute follow/override outcomes
    db.add_all([
        Reflection(
            purchase_id=purchase_follow.id,
            user_id=user.id,
            window_days=7,
            regret_score=2,
            felt_financial_pressure=False,
            triggered_at=datetime.now(timezone.utc),
        ),
        Reflection(
            purchase_id=purchase_override.id,
            user_id=user.id,
            window_days=7,
            regret_score=5,
            felt_financial_pressure=True,
            triggered_at=datetime.now(timezone.utc),
        ),
    ])
    db.commit()

    response = client.get(
        f"/api/v1/analytics/{user.id}/decision-quality?lookback_days=30&min_sample=1",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()

    assert data["total_shown"] == 2
    assert data["accepted_count"] == 1
    assert data["overridden_count"] == 1
    assert data["acceptance_rate"] == 50.0
    assert data["override_rate"] == 50.0
    assert data["helpful_rate"] == 100.0
    assert data["follow_regret_rate"] == 0.0
    assert data["override_regret_rate"] == 100.0
    assert data["override_pressure_rate"] == 100.0
    assert len(data["breakdown_by_factor"]) >= 1
    assert len(data["breakdown_by_verdict"]) >= 1
    db.close()


def test_decision_quality_respects_lookback():
    db = TestingSessionLocal()
    user = create_test_user(db)
    token = get_token(user)

    old_event = Purchase(
        user_id=user.id,
        item_name="Old Item",
        price_cents=1000,
        category="Misc",
        status="EVALUATED",
        affordability_score=80,
        risk_level="LOW",
        days_impacted_predicted=0.1,
        created_at=datetime.now(timezone.utc) - timedelta(days=45),
    )
    db.add(old_event)
    db.commit()
    db.refresh(old_event)

    # Insert an old event directly with created_at out of lookback window.
    from app.models.decision_event import DecisionEvent

    event = DecisionEvent(
        user_id=user.id,
        purchase_id=old_event.id,
        event_type="verdict_shown",
        verdict="Delay",
        dominant_factor="behavior",
        created_at=datetime.now(timezone.utc) - timedelta(days=45),
    )
    db.add(event)
    db.commit()

    response = client.get(
        f"/api/v1/analytics/{user.id}/decision-quality?lookback_days=30",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["total_shown"] == 0
    db.close()


def test_decision_quality_trends_weekly_and_category():
    db = TestingSessionLocal()
    user = create_test_user(db)
    token = get_token(user)

    p_food = Purchase(
        user_id=user.id,
        item_name="Coffee Machine",
        price_cents=18000,
        category="Food",
        status="ABANDONED",
        affordability_score=70,
        risk_level="MEDIUM",
        days_impacted_predicted=2.0,
    )
    p_tech = Purchase(
        user_id=user.id,
        item_name="Monitor",
        price_cents=35000,
        category="Tech",
        status="BOUGHT",
        affordability_score=40,
        risk_level="HIGH",
        days_impacted_predicted=5.0,
    )
    db.add_all([p_food, p_tech])
    db.commit()
    db.refresh(p_food)
    db.refresh(p_tech)

    # Create verdict and action events in different weeks.
    from app.models.decision_event import DecisionEvent

    now = datetime.now(timezone.utc)
    older = now - timedelta(days=8)
    db.add_all([
        DecisionEvent(
            user_id=user.id,
            purchase_id=p_food.id,
            event_type="verdict_shown",
            verdict="Delay",
            dominant_factor="behavior",
            category="Food",
            created_at=older,
        ),
        DecisionEvent(
            user_id=user.id,
            purchase_id=p_food.id,
            event_type="action_selected",
            verdict="Delay",
            dominant_factor="behavior",
            category="Food",
            overrode_recommendation=False,
            created_at=older,
        ),
        DecisionEvent(
            user_id=user.id,
            purchase_id=p_tech.id,
            event_type="verdict_shown",
            verdict="Avoid",
            dominant_factor="affordability",
            category="Tech",
            created_at=now,
        ),
        DecisionEvent(
            user_id=user.id,
            purchase_id=p_tech.id,
            event_type="action_selected",
            verdict="Avoid",
            dominant_factor="affordability",
            category="Tech",
            overrode_recommendation=True,
            created_at=now,
        ),
    ])
    db.commit()

    response = client.get(
        f"/api/v1/analytics/{user.id}/decision-quality/trends?lookback_days=30&min_sample=1",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()

    assert data["lookback_days"] == 30
    assert data["min_sample"] == 1
    assert len(data["weekly"]) >= 2
    assert len(data["by_category"]) == 2

    category_keys = {entry["bucket"] for entry in data["by_category"]}
    assert "Food" in category_keys
    assert "Tech" in category_keys

    for entry in data["weekly"]:
        assert "summary" in entry
        assert "total_shown" in entry["summary"]
        assert "acceptance_rate" in entry["summary"]

    db.close()
