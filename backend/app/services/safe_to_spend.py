from datetime import date, timedelta
from typing import Tuple, List, Dict

def calculate_safe_to_spend(user) -> Tuple[int, int, int, List[Dict]]:
    """
    Calculates Safe-to-Spend using the exact Iteration 9 specifications.
    Finds the next income date.
    Finds all fixed expenses between now and that date.
    Subtracts those expenses from the current_balance.
    Applies a 10% safety buffer.
    Returns (safe_to_spend_cents, days_to_next_bill, next_bill_amount_cents).
    """
    today = date.today()
    
    # Find next income date
    if not user.incomes:
        # Default to 30 days if no incomes
        next_income_date = today + timedelta(days=30)
    else:
        # Sort by closest next_paydate
        valid_incomes = [inc for inc in user.incomes if inc.next_paydate and inc.next_paydate >= today]
        if valid_incomes:
            next_income = min(valid_incomes, key=lambda i: (i.next_paydate - today).days)
            next_income_date = next_income.next_paydate
        else:
            next_income_date = today + timedelta(days=30)
            
    # Find next bill and expenses between now and next_income_date
    total_expenses_cents = 0
    
    next_bill_days = 0
    next_bill_amount_cents = 0
    
    # We only consider fixed expenses
    # Expense due date is an integer `due_date_day` (1-31)
    current_date = today
    
    # To track the closest bill
    closest_bill_date = None
    
    bills = []
    
    for expense in user.expenses:
        if not expense.is_fixed or not expense.due_date_day:
            continue
            
        # Find all occurrences of this bill between today and next_income_date
        temp_date = current_date
        # Check current month, and up to whatever month next_income_date is in
        while temp_date.year < next_income_date.year or (temp_date.year == next_income_date.year and temp_date.month <= next_income_date.month):
            try:
                bill_date = date(temp_date.year, temp_date.month, expense.due_date_day)
                if current_date <= bill_date <= next_income_date:
                    bills.append((bill_date, expense.amount_cents, expense.name))
            except ValueError:
                # e.g. Feb 30 -> handle by selecting last day of month if necessary
                # for simplicity, let's fast forward to last day
                from calendar import monthrange
                last_day = monthrange(temp_date.year, temp_date.month)[1]
                if expense.due_date_day > last_day:
                    bill_date = date(temp_date.year, temp_date.month, last_day)
                    if current_date <= bill_date <= next_income_date:
                        bills.append((bill_date, expense.amount_cents, expense.name))
            
            # Move to next month
            month = temp_date.month + 1
            year = temp_date.year
            if month > 12:
                month = 1
                year += 1
            temp_date = date(year, month, 1)

    # Sort bills by date
    bills.sort(key=lambda x: x[0])
    
    upcoming_bills_all = []
    
    for b_date, b_amount, b_name in bills:
        total_expenses_cents += b_amount
        if closest_bill_date is None or b_date < closest_bill_date:
            closest_bill_date = b_date
            next_bill_amount_cents = b_amount
            
        upcoming_bills_all.append({
            'name': b_name,
            'amount_cents': b_amount,
            'date': b_date.isoformat(),
            'days_until': (b_date - today).days
        })
        
    if closest_bill_date:
        next_bill_days = (closest_bill_date - today).days
        
    balance = user.current_balance_cents or 0
    raw_safe = balance - total_expenses_cents
    
    if raw_safe < 0:
        safe_to_spend = 0
    else:
        # Keep a 10% safety buffer (so available to spend is 90%)
        safe_to_spend = int(raw_safe * 0.9)
        
    # Limit to top 3 upcoming bills
    upcoming_bills = upcoming_bills_all[:3]
        
    return safe_to_spend, next_bill_days, next_bill_amount_cents, upcoming_bills
