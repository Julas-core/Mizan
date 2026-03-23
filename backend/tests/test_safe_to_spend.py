import pytest
from datetime import date, timedelta
from unittest.mock import patch
from app.services.safe_to_spend import calculate_safe_to_spend

class MockIncome:
    def __init__(self, next_paydate):
        self.next_paydate = next_paydate

class MockExpense:
    def __init__(self, is_fixed, due_date_day, amount_cents, name="Test Bill"):
        self.is_fixed = is_fixed
        self.due_date_day = due_date_day
        self.amount_cents = amount_cents
        self.name = name

class MockUser:
    def __init__(self, incomes, expenses, current_balance_cents):
        self.incomes = incomes
        self.expenses = expenses
        self.current_balance_cents = current_balance_cents

@patch('app.services.safe_to_spend.date')
def test_calculate_safe_to_spend(mock_date):
    # Mock today to be 2026-03-23
    mock_date.today.return_value = date(2026, 3, 23)
    mock_date.side_effect = lambda *args, **kw: date(*args, **kw)
    
    incomes = [MockIncome(date(2026, 4, 15))] # Next income is in 23 days
    # Expenses: one on 31st (maps to 31st of Mar), one on 5th (maps to 5th of Apr)
    expenses = [
        MockExpense(True, 31, 10000), # 100.00
        MockExpense(True, 5, 20000)   # 200.00
    ]
    user = MockUser(incomes, expenses, 50000) # 500.00 current balance

    # Total buffer = 500.00 - 300.00 = 200.00
    # Safe to spend = 200.00 * 0.9 = 180.00 (18000 cents)
    # Next bill is 31st (8 days away), amount 100.00 (10000 cents)
    safe_to_spend, next_bill_days, next_bill_amount_cents, upcoming_bills = calculate_safe_to_spend(user)
    
    assert safe_to_spend == 18000
    assert next_bill_days == 8
    assert next_bill_amount_cents == 10000
    assert len(upcoming_bills) == 2

@patch('app.services.safe_to_spend.date')
def test_calculate_safe_to_spend_no_incomes(mock_date):
    mock_date.today.return_value = date(2026, 3, 23)
    mock_date.side_effect = lambda *args, **kw: date(*args, **kw)
    
    # 30 days from 3-23 is 4-22. Bill on 15th will be hit.
    user = MockUser([], [MockExpense(True, 15, 5000)], 20000)
    
    # Needs to process bill on 4-15 which is 23 days away
    # Total expenses = 5000 (50.00)
    # Balance = 20000 (200.00)
    # 20000 - 5000 = 15000
    # 15000 * 0.9 = 13500 cents
    
    safe_to_spend, days, amt, upcoming_bills = calculate_safe_to_spend(user)
    assert safe_to_spend == 13500
    assert days == 23
    assert amt == 5000
