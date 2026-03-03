import sys
import os
import uuid
from datetime import date, timedelta

sys.path.insert(0, os.path.dirname(__file__))

from app.db.session import SessionLocal
from app.models.user import User
from app.models.income import Income
from app.models.expense import Expense
from app.models.goal import Goal
from app.db.base import Base
from app.db.session import engine

def seed_db():
    print("Recreating database tables...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    # 1. Create User
    user_id = "test-user-123"
    db_user = User(id=user_id)
    db.add(db_user)
    
    # 2. Add Monthly Income ($3000)
    db_income = Income(
        id=str(uuid.uuid4()),
        user_id=user_id,
        amount_cents=450000, # $4500
        frequency="Monthly",
        next_paydate=date.today() + timedelta(days=15),
        confidence_score=1.0
    )
    db.add(db_income)
    
    # 3. Add Rent ($1200) and Groceries ($400)
    db_rent = Expense(
        id=str(uuid.uuid4()),
        user_id=user_id,
        name="Rent",
        amount_cents=120000,
        is_fixed=True,
        due_date_day=1
    )
    db_groceries = Expense(
        id=str(uuid.uuid4()),
        user_id=user_id,
        name="Groceries",
        amount_cents=40000,
        is_fixed=False,
    )
    db.add(db_rent)
    db.add(db_groceries)
    
    # 4. Add Savings Goals
    db_goal_1 = Goal(
        id="goal-laptop",
        user_id=user_id,
        name="New Laptop",
        target_amount_cents=150000, # $1500
        priority=1
    )
    db_goal_2 = Goal(
        id="goal-vacation",
        user_id=user_id,
        name="Summer Vacation",
        target_amount_cents=300000, # $3000
        priority=2
    )
    db.add(db_goal_1)
    db.add(db_goal_2)
    
    db.commit()
    print(f"Seed complete. Testing UserId: {user_id}")

if __name__ == "__main__":
    seed_db()
