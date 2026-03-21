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
