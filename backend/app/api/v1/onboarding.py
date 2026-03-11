from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.api import dependencies
from app.api.dependencies import get_current_user, require_same_user
from app.models.user import User as UserModel
from app.models.income import Income as IncomeModel
from app.models.expense import Expense as ExpenseModel
from app.models.goal import Goal as GoalModel

from app.schemas.income import Income as IncomeSchema, IncomeCreate
from app.schemas.expense import Expense as ExpenseSchema, ExpenseCreate
from app.schemas.goal import Goal as GoalSchema, GoalCreate

router = APIRouter()

def get_user_or_404(db: Session, user_id: str) -> UserModel:
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.post("/{user_id}/income", response_model=IncomeSchema, status_code=status.HTTP_201_CREATED)
def setup_income(user_id: str, income_in: IncomeCreate, db: Session = Depends(dependencies.get_db), current_user = Depends(get_current_user)):
    """
    Setup income details for a user.
    """
    require_same_user(current_user, user_id)
    get_user_or_404(db, user_id)
    db_income = IncomeModel(
        user_id=user_id,
        amount_cents=income_in.amount_cents,
        frequency=income_in.frequency,
        next_paydate=income_in.next_paydate,
        confidence_score=income_in.confidence_score
    )
    db.add(db_income)
    db.commit()
    db.refresh(db_income)
    return db_income

@router.post("/{user_id}/expenses", response_model=ExpenseSchema, status_code=status.HTTP_201_CREATED)
def add_fixed_expense(user_id: str, expense_in: ExpenseCreate, db: Session = Depends(dependencies.get_db), current_user = Depends(get_current_user)):
    """
    Add a fixed expense for a user.
    """
    require_same_user(current_user, user_id)
    get_user_or_404(db, user_id)
    db_expense = ExpenseModel(
        user_id=user_id,
        name=expense_in.name,
        amount_cents=expense_in.amount_cents,
        is_fixed=expense_in.is_fixed,
        due_date_day=expense_in.due_date_day
    )
    db.add(db_expense)
    db.commit()
    db.refresh(db_expense)
    return db_expense

@router.post("/{user_id}/goal", response_model=GoalSchema, status_code=status.HTTP_201_CREATED)
def set_savings_goal(user_id: str, goal_in: GoalCreate, db: Session = Depends(dependencies.get_db), current_user = Depends(get_current_user)):
    """
    Set a custom savings goal for a user.
    """
    require_same_user(current_user, user_id)
    get_user_or_404(db, user_id)
    db_goal = GoalModel(
        user_id=user_id,
        name=goal_in.name,
        target_amount_cents=goal_in.target_amount_cents,
        priority=goal_in.priority,
        image_url=goal_in.image_url
    )
    db.add(db_goal)
    db.commit()
    db.refresh(db_goal)
    return db_goal


@router.get("/{user_id}/goals", response_model=List[GoalSchema])
def list_savings_goals(
    user_id: str, 
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(dependencies.get_db), 
    current_user = Depends(get_current_user)
):
    """
    List all savings goals for a user.
    """
    require_same_user(current_user, user_id)
    get_user_or_404(db, user_id)
    return (
        db.query(GoalModel)
        .filter(GoalModel.user_id == user_id)
        .order_by(GoalModel.priority.asc())
        .offset(skip)
        .limit(limit)
        .all()
    )
