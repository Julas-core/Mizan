import pytest
from datetime import timedelta
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.api.dependencies import get_db
from app.db.base_class import Base
from app.models.user import User
from app.core.security import create_access_token, hash_password

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_auth.db"
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

def test_register_and_login():
    # 1. Register
    response = client.post(
        "/api/v1/auth/register",
        json={"email": "test@example.com", "password": "supersecurepassword"}
    )
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    user_id = data["user_id"]

    # 2. Login
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "test@example.com", "password": "supersecurepassword"}
    )
    assert login_response.status_code == 200
    login_data = login_response.json()
    assert "access_token" in login_data
    assert login_data["user_id"] == user_id


def test_duplicate_email_registration():
    client.post(
        "/api/v1/auth/register",
        json={"email": "dup@example.com", "password": "password123"}
    )
    # Register again with same email
    response = client.post(
        "/api/v1/auth/register",
        json={"email": "dup@example.com", "password": "password456"}
    )
    assert response.status_code == 409
    assert response.json()["error"] == "Email already registered"


def test_no_token_returns_401():
    # Access a protected route without token (get_user_summary)
    response = client.get("/api/v1/users/some-fake-id/summary")
    assert response.status_code == 401


def test_invalid_token_returns_401():
    response = client.get(
        "/api/v1/users/some-id/summary",
        headers={"Authorization": "Bearer not-a-real-token"}
    )
    assert response.status_code == 401


def test_expired_token_returns_401():
    # Create an expired token manually
    expired_token = create_access_token(
        user_id="test_user_id",
        email="test@example.com",
        expires_delta=timedelta(minutes=-10)  # Expired 10 mins ago
    )
    response = client.get(
        "/api/v1/users/test_user_id/summary",
        headers={"Authorization": f"Bearer {expired_token}"}
    )
    assert response.status_code == 401


def test_wrong_user_returns_403():
    # Setup two users manually in DB to test ownership guards
    db = TestingSessionLocal()
    userA = User(email="usera@example.com", hashed_password=hash_password("pw"))
    userB = User(email="userb@example.com", hashed_password=hash_password("pw"))
    db.add(userA)
    db.add(userB)
    db.commit()
    db.refresh(userA)
    db.refresh(userB)

    # Login as User A
    token_a = create_access_token(user_id=userA.id, email=userA.email)

    # User A tries to get User B's summary
    response = client.get(
        f"/api/v1/users/{userB.id}/summary",
        headers={"Authorization": f"Bearer {token_a}"}
    )
    # The get_current_user logic will allow auth, but require_same_user should yield 403
    assert response.status_code == 403

    db.close()
