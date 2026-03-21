import math
import logging
from datetime import date, timedelta
from typing import List, Dict, Optional, Any
from pydantic import BaseModel

logger = logging.getLogger(__name__)

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

class GoalDelayDetail(BaseModel):
    delay_days: Optional[float] = None
    relative_delay_pct: Optional[float] = None  # e.g. 0.18 = "delays goal by 18%"
    unreachable: bool = False

class EvaluationResult(BaseModel):
    affordability_score: int
    risk_level: str
    days_impacted: float
    liquidity_failure: bool
    deficit_mode: bool
    goals_delayed: Dict[str, float]  # legacy: goal_id -> delay days
    goal_delay_days: Dict[str, Any] = {}  # goal_id -> GoalDelayDetail dict
    risk_breakdown: Dict[str, Any] = {}  # structured explanation
    behavior_penalty: float = 0.0
    behavior_explanation: str = ""

# --- Constants & Risk Thresholds ---
HORIZON_DAYS = 30
UNCERTAINTY_MARGIN_PCT = 0.05
LOGISTIC_MIDPOINT = 0.5  # 50% of budget consumed
LOGISTIC_K_FACTOR = 10   # Steepness of the risk curve
EARLY_CREDIT_FREQUENCIES = {"Weekly", "Biweekly"}
MIN_GOAL_WINDOW_DAYS = 7  # default, can be overridden from config

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

def simulate_goal_delays(
    item_price_cents: int,
    goals: List[EngineGoal],
    daily_safe_capacity: float,
    min_goal_window_days: int = MIN_GOAL_WINDOW_DAYS,
) -> tuple[Dict[str, float], Dict[str, dict]]:
    """
    Compute both legacy goals_delayed and detailed goal_delay_days.
    
    Returns:
        (goals_delayed, goal_delay_days)
        - goals_delayed: {goal_id: delay_days} (legacy format)
        - goal_delay_days: {goal_id: {delay_days, relative_delay_pct, unreachable}}
    """
    goals_delayed: Dict[str, float] = {}
    goal_delay_days: Dict[str, dict] = {}
    remaining_impact_cents = item_price_cents

    sorted_goals = sorted(goals, key=lambda g: g.priority)

    for g in sorted_goals:
        if remaining_impact_cents <= 0:
            break

        deduction = min(remaining_impact_cents, g.target_amount_cents)

        # Guard: division by zero or negative savings rate
        if daily_safe_capacity <= 0:
            goals_delayed[g.id] = 0.0
            goal_delay_days[g.id] = GoalDelayDetail(
                unreachable=True
            ).model_dump()
        else:
            delayed_days = deduction / daily_safe_capacity
            goals_delayed[g.id] = round(delayed_days, 1)

            # Compute relative delay
            remaining_days = g.target_amount_cents / daily_safe_capacity
            if remaining_days <= min_goal_window_days:
                # Goal window too small for meaningful percentage
                goal_delay_days[g.id] = GoalDelayDetail(
                    delay_days=round(delayed_days, 1),
                    relative_delay_pct=None,
                ).model_dump()
            else:
                rel_pct = round(delayed_days / remaining_days, 3)
                goal_delay_days[g.id] = GoalDelayDetail(
                    delay_days=round(delayed_days, 1),
                    relative_delay_pct=rel_pct,
                ).model_dump()

        remaining_impact_cents -= deduction

    return goals_delayed, goal_delay_days


def evaluate_purchase(
    item_price_cents: int,
    starting_cash_cents: int,
    incomes: List[EngineIncome],
    expenses: List[EngineExpense] | EngineExpense,
    goals: List[EngineGoal],
    current_date: date = date.today(),
    behavior_penalty: float = 0.0,
    behavior_explanation: str = "",
    risk_weights: Optional[tuple[float, float, float]] = None,
    max_behavior_penalty: float = 0.25,
    min_goal_window_days: int = MIN_GOAL_WINDOW_DAYS,
) -> EvaluationResult:
    """
    The master evaluation algorithm. Evaluates the risk and impact of buying an item TODAY.
    Now integrates the composite risk model with behavior penalties and goal delay simulation.
    """
    from app.services.risk_model import compute_composite_risk, explain_risk

    normalized_expenses = expenses if isinstance(expenses, list) else [expenses]
    w_afford, w_behave, w_goal = risk_weights or (0.5, 0.3, 0.2)

    # 1. Run baseline simulation (If we DON'T buy the item)
    baseline_incomes = [EngineIncome(**inc.model_dump()) for inc in incomes]
    baseline_timeline = simulate_cashflow_timeline(current_date, starting_cash_cents, baseline_incomes, normalized_expenses)

    total_inflows = sum(b - baseline_timeline[i-1] for i, b in enumerate(baseline_timeline) if i > 0 and b > baseline_timeline[i-1])
    total_inflows = max(total_inflows, 1)

    cycle_budget = baseline_timeline[-1] - starting_cash_cents

    # --- Edge Case 1: Deficit Mode ---
    if cycle_budget <= 1e-6:
        return EvaluationResult(
            affordability_score=0,
            risk_level="Severe Risk (Deficit)",
            days_impacted=0.0,
            liquidity_failure=True,
            deficit_mode=True,
            goals_delayed={},
            behavior_penalty=behavior_penalty,
            behavior_explanation=behavior_explanation,
        )

    daily_safe_capacity = total_inflows / HORIZON_DAYS

    # --- 2. Run Purchase Simulation ---
    purchase_incomes = [EngineIncome(**inc.model_dump()) for inc in incomes]
    purchase_timeline = simulate_cashflow_timeline(current_date, starting_cash_cents - item_price_cents, purchase_incomes, normalized_expenses)

    liquidity_failure = any(balance < 0 for balance in purchase_timeline)

    if liquidity_failure:
        return EvaluationResult(
            affordability_score=0,
            risk_level="Severe Risk (Liquidity Failure)",
            days_impacted=item_price_cents / daily_safe_capacity,
            liquidity_failure=True,
            deficit_mode=False,
            goals_delayed={},
            behavior_penalty=behavior_penalty,
            behavior_explanation=behavior_explanation,
        )

    # --- Standard Evaluation ---
    budget_consumed_pct = item_price_cents / cycle_budget
    affordability_score = calculate_nonlinear_affordability(budget_consumed_pct)

    days_impacted = item_price_cents / daily_safe_capacity

    # --- Goal Delay Simulation ---
    goals_delayed, goal_delay_days = simulate_goal_delays(
        item_price_cents=item_price_cents,
        goals=goals,
        daily_safe_capacity=daily_safe_capacity,
        min_goal_window_days=min_goal_window_days,
    )

    # --- Composite Risk Score ---
    budget_pressure = min(budget_consumed_pct, 1.0)

    # Goal delay impact: average relative delay across all affected goals (0-1)
    relative_delays = [
        d.get("relative_delay_pct", 0) or 0
        for d in goal_delay_days.values()
        if not d.get("unreachable", False)
    ]
    goal_delay_impact = min(sum(relative_delays) / max(len(relative_delays), 1), 1.0)

    risk_score = compute_composite_risk(
        budget_pressure=budget_pressure,
        behavior_penalty=behavior_penalty,
        goal_delay_impact=goal_delay_impact,
        w_afford=w_afford,
        w_behave=w_behave,
        w_goal=w_goal,
    )

    # Map composite score to risk level
    if risk_score < 20:
        risk_level = "Low Risk"
    elif risk_score < 50:
        risk_level = "Moderate Risk"
    elif risk_score < 75:
        risk_level = "High Risk"
    else:
        risk_level = "Severe Risk"

    risk_breakdown = explain_risk(
        budget_pressure=budget_pressure,
        behavior_penalty=behavior_penalty,
        goal_delay_impact=goal_delay_impact,
        final_score=risk_score,
        behavior_explanation=behavior_explanation,
    )

    return EvaluationResult(
        affordability_score=affordability_score,
        risk_level=risk_level,
        days_impacted=round(days_impacted, 1),
        liquidity_failure=False,
        deficit_mode=False,
        goals_delayed=goals_delayed,
        goal_delay_days=goal_delay_days,
        risk_breakdown=risk_breakdown,
        behavior_penalty=behavior_penalty,
        behavior_explanation=behavior_explanation,
    )
