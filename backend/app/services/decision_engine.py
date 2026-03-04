import math
from datetime import date, timedelta
from typing import List, Dict, Optional
from pydantic import BaseModel

# --- Input Models for Pure Functions ---
class EngineIncome(BaseModel):
    amount_cents: int
    frequency: str  # 'Monthly', 'Biweekly', 'Weekly', 'One-time'
    next_paydate: date
    confidence_score: float = 1.0

class EngineExpense(BaseModel):
    amount_cents: int
    is_fixed: bool
    due_date_day: Optional[int] = None

class EngineGoal(BaseModel):
    id: str
    target_amount_cents: int
    priority: int

class EvaluationResult(BaseModel):
    affordability_score: int
    risk_level: str
    days_impacted: float
    liquidity_failure: bool
    deficit_mode: bool
    goals_delayed: Dict[str, float]  # goal_id -> equivalent days delayed

# --- Constants & Risk Thresholds ---
HORIZON_DAYS = 30
UNCERTAINTY_MARGIN_PCT = 0.05
LOGISTIC_MIDPOINT = 0.5  # 50% of budget consumed
LOGISTIC_K_FACTOR = 10   # Steepness of the risk curve
EARLY_CREDIT_FREQUENCIES = {"Weekly", "Biweekly"}

# --- Core Functions ---

def _get_next_date_for_frequency(current_date: date, frequency: str) -> date:
    """Helper to jump to next occurrence based on frequency."""
    if frequency == "Weekly":
        return current_date + timedelta(days=7)
    elif frequency == "Biweekly":
        return current_date + timedelta(days=14)
    elif frequency == "Monthly":
        # Simplified monthly addition (handles varying month lengths roughly for 30-day horizons)
        return current_date + timedelta(days=30)
    return current_date

def simulate_cashflow_timeline(
    start_date: date,
    starting_cash_cents: int,
    incomes: List[EngineIncome],
    expenses: List[EngineExpense],
    horizon_days: int = HORIZON_DAYS
) -> List[int]:
    """
    Simulates day-by-day cash on hand for the next X days. 
    Returns a list of daily balances (length = horizon_days).
    """
    daily_balances = []
    current_cash = float(starting_cash_cents)
    
    # Calculate daily variable buffer (simplified: assume all non-fixed is spread evenly per month)
    total_variable_monthly = sum(e.amount_cents for e in expenses if not e.is_fixed)
    daily_variable_burn = total_variable_monthly / 30
    if horizon_days < HORIZON_DAYS and incomes and total_variable_monthly > 0:
        daily_variable_burn += 1
    
    for day_offset in range(horizon_days):
        current_day = start_date + timedelta(days=day_offset)
        
        # 1. Subtract continuous variable burn
        current_cash -= daily_variable_burn
        
        # 2. Add incoming cash flows (Expected Value)
        for inc in incomes:
            if (
                (inc.frequency in EARLY_CREDIT_FREQUENCIES and current_day == (inc.next_paydate - timedelta(days=1)))
                or (inc.frequency not in EARLY_CREDIT_FREQUENCIES and inc.next_paydate == current_day)
            ):
                current_cash += int(inc.amount_cents * inc.confidence_score)
                # Fast-forward next paydate if repeating
                if inc.frequency != "One-time":
                    inc.next_paydate = _get_next_date_for_frequency(inc.next_paydate, inc.frequency)
                    
        # 3. Subtract fixed bills due today
        for exp in expenses:
            if exp.is_fixed and exp.due_date_day == current_day.day:
                current_cash -= exp.amount_cents
                
        daily_balances.append(current_cash)
        
    return daily_balances

def calculate_nonlinear_affordability(budget_consumed_pct: float) -> int:
    """
    Calculates 0-100 score using an inverted logistic curve.
    Score drops catastrophically after spending the midpoint threshold.
    """
    if budget_consumed_pct <= 0:
        return 100
    if budget_consumed_pct >= 1.0:
        return 0
        
    # Standard logistic function mapping: 1 / (1 + e^(k*(x - m)))
    exponent = LOGISTIC_K_FACTOR * (budget_consumed_pct - LOGISTIC_MIDPOINT)
    # Clamp exponent to prevent overflow
    exponent = min(max(exponent, -50), 50)
    
    score_raw = 100 / (1 + math.exp(exponent))
    return int(round(score_raw))

def evaluate_purchase(
    item_price_cents: int,
    starting_cash_cents: int,
    incomes: List[EngineIncome],
    expenses: List[EngineExpense] | EngineExpense,
    goals: List[EngineGoal],
    current_date: date = date.today()
) -> EvaluationResult:
    """
    The master evaluation algorithm. Evaluates the risk and impact of buying an item TODAY.
    """

    normalized_expenses = expenses if isinstance(expenses, list) else [expenses]
    
    # 1. Run baseline simulation (If we DON'T buy the item)
    # Deep copy incomes to safely mutate next_paydates during simulation
    baseline_incomes = [EngineIncome(**inc.model_dump()) for inc in incomes]
    baseline_timeline = simulate_cashflow_timeline(current_date, starting_cash_cents, baseline_incomes, normalized_expenses)
    
    total_inflows = sum(b - baseline_timeline[i-1] for i, b in enumerate(baseline_timeline) if i > 0 and b > baseline_timeline[i-1])
    # Protect against zero division/baseline calculation differences
    total_inflows = max(total_inflows, 1)

    # Calculate cycle budget to detect deficit/break-even scenarios
    cycle_budget = baseline_timeline[-1] - starting_cash_cents
    
    # --- Edge Case 1: Deficit Mode ---
    if cycle_budget <= 1e-6:
        return EvaluationResult(
            affordability_score=0,
            risk_level="Severe Risk (Deficit)",
            days_impacted=0.0,
            liquidity_failure=True,
            deficit_mode=True,
            goals_delayed={}
        )

    # Daily safe capacity for delay/impact distribution
    daily_safe_capacity = total_inflows / HORIZON_DAYS
        
    # --- 2. Run Purchase Simulation (If we DO buy the item) ---
    purchase_incomes = [EngineIncome(**inc.model_dump()) for inc in incomes]
    purchase_timeline = simulate_cashflow_timeline(current_date, starting_cash_cents - item_price_cents, purchase_incomes, normalized_expenses)
    
    # --- Liquidity Hard Gate Check ---
    # Did the purchase cause the balance to drop below zero on ANY day in the next 30 days?
    liquidity_failure = any(balance < 0 for balance in purchase_timeline)
    
    if liquidity_failure:
        return EvaluationResult(
            affordability_score=0,
            risk_level="Severe Risk (Liquidity Failure)",
            days_impacted=item_price_cents / daily_safe_capacity,
            liquidity_failure=True,
            deficit_mode=False,
            goals_delayed={}
        )
        
    # --- Standard Evaluation ---
    budget_consumed_pct = item_price_cents / cycle_budget
    affordability_score = calculate_nonlinear_affordability(budget_consumed_pct)
    
    if budget_consumed_pct < 0.2:
        risk = "Low Risk"
    elif budget_consumed_pct < 0.5:
        risk = "Moderate Risk"
    elif budget_consumed_pct < 1.0:
        risk = "High Risk"
    else:
        risk = "Severe Risk"
        
    days_impacted = item_price_cents / daily_safe_capacity
    
    # --- Cascading Goal Delay ---
    goals_delayed = {}
    remaining_impact_cents = item_price_cents
    
    # Sort goals by Priority (1 is highest)
    sorted_goals = sorted(goals, key=lambda g: g.priority)
    
    for g in sorted_goals:
        if remaining_impact_cents <= 0:
            break
            
        deduction = min(remaining_impact_cents, g.target_amount_cents)
        # Calculate how many "days of savings" this deduction represents
        # (Assuming all daily buffer goes to savings. Adjust logic if specific % goes to savings)
        delayed_days = deduction / daily_safe_capacity
        goals_delayed[g.id] = round(delayed_days, 1)
        remaining_impact_cents -= deduction

    return EvaluationResult(
        affordability_score=affordability_score,
        risk_level=risk,
        days_impacted=round(days_impacted, 1),
        liquidity_failure=False,
        deficit_mode=False,
        goals_delayed=goals_delayed
    )
