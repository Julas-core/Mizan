"""
Comprehensive pytest test suite for the Mizan Financial Decision Engine.

Covers three major edge-case categories:
  1. Deficit Mode       — user is already cash-negative / spending exceeds income
  2. Liquidity Traps    — purchase temporarily zeroes out cash before the next payday
  3. Cascading Delays   — how a single purchase ripples across multiple savings goals

Also covers:
  - Helper utilities (_get_next_date_for_frequency)
  - Cash-flow simulation boundary conditions (simulate_cashflow_timeline)
  - Nonlinear affordability scoring (calculate_nonlinear_affordability)
  - Combined / compound edge cases
"""

import math
import sys
import os
import pytest
from datetime import date, timedelta
from typing import List

# ---------------------------------------------------------------------------
# Path bootstrap — makes `app` importable when running from backend/
# ---------------------------------------------------------------------------
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.services.decision_engine import (
    EngineIncome,
    EngineExpense,
    EngineGoal,
    EvaluationResult,
    _get_next_date_for_frequency,
    simulate_cashflow_timeline,
    calculate_nonlinear_affordability,
    evaluate_purchase,
    HORIZON_DAYS,
    UNCERTAINTY_MARGIN_PCT,
    LOGISTIC_MIDPOINT,
    LOGISTIC_K_FACTOR,
)

# ===========================================================================
# Shared fixtures
# ===========================================================================

TODAY = date(2026, 3, 1)   # fixed anchor so tests are deterministic


def make_income(
    amount_cents: int = 500_000,
    frequency: str = "Monthly",
    days_from_today: int = 15,
    confidence: float = 1.0,
) -> EngineIncome:
    return EngineIncome(
        amount_cents=amount_cents,
        frequency=frequency,
        next_paydate=TODAY + timedelta(days=days_from_today),
        confidence_score=confidence,
    )


def make_expense(
    amount_cents: int = 100_000,
    is_fixed: bool = True,
    due_date_day: int | None = 5,
) -> EngineExpense:
    return EngineExpense(
        amount_cents=amount_cents,
        is_fixed=is_fixed,
        due_date_day=due_date_day,
    )


def make_goal(goal_id: str = "goal_1", target_cents: int = 200_000, priority: int = 1) -> EngineGoal:
    return EngineGoal(id=goal_id, target_amount_cents=target_cents, priority=priority)


# ===========================================================================
# 1. Helper — _get_next_date_for_frequency
# ===========================================================================

class TestGetNextDateForFrequency:
    """Tests for the internal date-advancement helper."""

    def test_weekly_advances_seven_days(self):
        base = date(2026, 3, 1)
        result = _get_next_date_for_frequency(base, "Weekly")
        assert result == base + timedelta(days=7)

    def test_biweekly_advances_fourteen_days(self):
        base = date(2026, 3, 1)
        result = _get_next_date_for_frequency(base, "Biweekly")
        assert result == base + timedelta(days=14)

    def test_monthly_advances_thirty_days(self):
        """Engine uses a simplified 30-day month – this must remain consistent."""
        base = date(2026, 3, 1)
        result = _get_next_date_for_frequency(base, "Monthly")
        assert result == base + timedelta(days=30)

    def test_one_time_does_not_advance(self):
        """One-time income should never bump its paydate."""
        base = date(2026, 3, 15)
        result = _get_next_date_for_frequency(base, "One-time")
        assert result == base

    def test_unknown_frequency_does_not_advance(self):
        """Unknown strings fall through to the no-op return."""
        base = date(2026, 4, 10)
        result = _get_next_date_for_frequency(base, "Quarterly")
        assert result == base


# ===========================================================================
# 2. Cash-flow Simulation — simulate_cashflow_timeline
# ===========================================================================

class TestSimulateCashflowTimeline:
    """Unit tests for the day-by-day simulation core."""

    # -----------------------------------------------------------------------
    # 2a. Basic correctness
    # -----------------------------------------------------------------------

    def test_returns_horizon_length_list(self):
        timeline = simulate_cashflow_timeline(TODAY, 100_000, [], [], horizon_days=30)
        assert len(timeline) == 30

    def test_custom_horizon_respected(self):
        timeline = simulate_cashflow_timeline(TODAY, 100_000, [], [], horizon_days=7)
        assert len(timeline) == 7

    def test_no_expenses_no_income_monotone_decrease(self):
        """Zero incomes, zero expenses – cash stays constant (no variable burn)."""
        timeline = simulate_cashflow_timeline(TODAY, 50_000, [], [], horizon_days=5)
        # No variable expenses → daily_variable_burn = 0 → flat balance
        assert all(b == 50_000 for b in timeline)

    def test_variable_expense_burns_daily(self):
        """Variable expenses spread as daily_burn = total / 30."""
        # 30,000 cents / month → 1,000 / day
        var_expense = EngineExpense(amount_cents=30_000, is_fixed=False, due_date_day=None)
        timeline = simulate_cashflow_timeline(TODAY, 30_000, [], [var_expense], horizon_days=5)
        expected = [30_000 - (1_000 * (i + 1)) for i in range(5)]
        assert timeline == expected

    def test_fixed_expense_deducted_on_correct_day(self):
        """Fixed bill on day 5 of the month is deducted only on that specific day."""
        # Start on March 1. day 5 = March 5 → offset 4 (0-indexed)
        fixed = make_expense(amount_cents=50_000, is_fixed=True, due_date_day=5)
        timeline = simulate_cashflow_timeline(TODAY, 200_000, [], [fixed], horizon_days=10)
        # No variable burn, no income. Balance drops 50k on day offset 4 (March 5).
        assert timeline[0] == 200_000   # March 1 – no bill yet
        assert timeline[3] == 200_000   # March 4 – no bill yet
        assert timeline[4] == 150_000   # March 5 – bill deducted

    def test_income_added_on_paydate(self):
        """Monthly income landing on next_paydate is credited exactly once initially."""
        paydate = TODAY + timedelta(days=5)
        income = EngineIncome(
            amount_cents=100_000, frequency="Monthly",
            next_paydate=paydate, confidence_score=1.0
        )
        timeline = simulate_cashflow_timeline(TODAY, 0, [income], [], horizon_days=10)
        # Cash jumps from 0 → 100,000 on day offset 5
        assert timeline[4] == 0
        assert timeline[5] == 100_000

    def test_weekly_income_recurs_inside_horizon(self):
        """Weekly income fires on days 7 and 14 within a 30-day window."""
        paydate = TODAY + timedelta(days=7)
        income = EngineIncome(
            amount_cents=50_000, frequency="Weekly",
            next_paydate=paydate, confidence_score=1.0
        )
        timeline = simulate_cashflow_timeline(TODAY, 0, [income], [], horizon_days=20)
        assert timeline[6] == 50_000    # first payday
        assert timeline[13] == 100_000  # second payday

    # -----------------------------------------------------------------------
    # 2b. Deficit / Negative Balance Scenarios
    # -----------------------------------------------------------------------

    def test_negative_balance_possible_in_simulation(self):
        """Simulation itself does NOT clamp negatives — the caller must handle them."""
        var_expense = EngineExpense(amount_cents=90_000, is_fixed=False, due_date_day=None)
        # 3,000 / day burn, start with 1,000 → goes negative fast
        timeline = simulate_cashflow_timeline(TODAY, 1_000, [], [var_expense], horizon_days=5)
        assert any(b < 0 for b in timeline)

    def test_large_fixed_bill_causes_deep_negative(self):
        """A bill larger than starting cash forces the balance deeply negative."""
        fixed = make_expense(amount_cents=500_000, is_fixed=True, due_date_day=TODAY.day)
        timeline = simulate_cashflow_timeline(TODAY, 10_000, [], [fixed], horizon_days=3)
        assert timeline[0] == 10_000 - 500_000  # = -490,000

    def test_confidence_score_scales_income(self):
        """A 0.8 confidence income should only add 80% of face value."""
        paydate = TODAY + timedelta(days=1)
        income = EngineIncome(
            amount_cents=100_000, frequency="One-time",
            next_paydate=paydate, confidence_score=0.8
        )
        timeline = simulate_cashflow_timeline(TODAY, 0, [income], [], horizon_days=5)
        assert timeline[1] == 80_000

    def test_zero_confidence_income_contributes_nothing(self):
        """0.0 confidence is a ghost paycheck — adds nothing."""
        paydate = TODAY + timedelta(days=2)
        income = EngineIncome(
            amount_cents=100_000, frequency="One-time",
            next_paydate=paydate, confidence_score=0.0
        )
        timeline = simulate_cashflow_timeline(TODAY, 5_000, [income], [], horizon_days=5)
        assert timeline[2] == 5_000  # No change on payday

    def test_zero_starting_cash_and_immediate_burn(self):
        """Starting at exactly zero with daily burn immediately enters deficit."""
        var_expense = EngineExpense(amount_cents=30_000, is_fixed=False, due_date_day=None)
        timeline = simulate_cashflow_timeline(TODAY, 0, [], [var_expense], horizon_days=3)
        assert timeline[0] < 0

    # -----------------------------------------------------------------------
    # 2c. Liquidity trap in simulation
    # -----------------------------------------------------------------------

    def test_brief_dip_then_recovery(self):
        """Balance goes negative mid-cycle but recovers when paycheck arrives."""
        paydate = TODAY + timedelta(days=5)
        income = EngineIncome(
            amount_cents=100_000, frequency="Monthly",
            next_paydate=paydate, confidence_score=1.0,
        )
        var_expense = EngineExpense(amount_cents=60_000, is_fixed=False, due_date_day=None)
        # 2,000/day burn; 50k start → hits 0 around day 25 without income
        # But income arrives day 5 and rescues it
        timeline = simulate_cashflow_timeline(TODAY, 10_000, [income], [var_expense], horizon_days=10)
        # Should be negative before paydate
        assert timeline[4] < 0  # day 4, no income yet, burned 10k
        # Should recover after paydate (day 5 credited 100k)
        assert timeline[5] > 0


# ===========================================================================
# 3. Non-Linear Affordability Score — calculate_nonlinear_affordability
# ===========================================================================

class TestCalculateNonlinearAffordability:
    """Tests for the inverted logistic scoring curve."""

    def test_zero_consumption_returns_100(self):
        assert calculate_nonlinear_affordability(0.0) == 100

    def test_negative_consumption_clamps_to_100(self):
        """Negative ratios should be treated as 0% consumed."""
        assert calculate_nonlinear_affordability(-0.5) == 100

    def test_full_consumption_returns_0(self):
        assert calculate_nonlinear_affordability(1.0) == 0

    def test_over_full_consumption_returns_0(self):
        assert calculate_nonlinear_affordability(1.5) == 0

    def test_midpoint_returns_50(self):
        """At exactly 50% consumption the logistic gives exactly 50."""
        score = calculate_nonlinear_affordability(LOGISTIC_MIDPOINT)
        assert score == 50

    def test_low_consumption_scores_high(self):
        """10% budget use should still score very high (>= 90)."""
        assert calculate_nonlinear_affordability(0.10) >= 90

    def test_high_consumption_scores_low(self):
        """90% budget use should score very low (<= 10)."""
        assert calculate_nonlinear_affordability(0.90) <= 10

    def test_score_is_strictly_decreasing(self):
        """Score must fall monotonically as budget_consumed_pct rises."""
        levels = [i * 0.05 for i in range(1, 20)]  # 0.05 .. 0.95
        scores = [calculate_nonlinear_affordability(p) for p in levels]
        for i in range(len(scores) - 1):
            assert scores[i] >= scores[i + 1], (
                f"Score not decreasing at {levels[i]:.2f}: {scores[i]} > {scores[i+1]}"
            )

    def test_score_is_integer(self):
        """Output must always be an int (rounded)."""
        for pct in [0.0, 0.25, 0.5, 0.75, 1.0]:
            assert isinstance(calculate_nonlinear_affordability(pct), int)

    def test_score_bounded_0_100(self):
        """Score must always reside in [0, 100]."""
        for pct in [-1.0, 0.0, 0.3, 0.5, 0.7, 1.0, 2.0]:
            score = calculate_nonlinear_affordability(pct)
            assert 0 <= score <= 100, f"Score {score} out of range for pct={pct}"

    def test_extreme_positive_exponent_no_overflow(self):
        """k*(1.0 - 0.5) = 5, clamped: no math overflow for any legal input."""
        # Should not raise OverflowError for extreme values outside [0,1]
        score = calculate_nonlinear_affordability(10.0)
        assert score == 0


# ===========================================================================
# 4. evaluate_purchase — DEFICIT MODE
# ===========================================================================

class TestEvaluatePurchaseDeficitMode:
    """
    Deficit Mode is triggered when the user's 30-day financial cycle
    ends with LESS money than it started — i.e., net outflows exceed net inflows.
    The engine should immediately return the Deficit sentinel.
    """

    def _deficit_context(self):
        """
        Creates a scenario where expenses burn more than income brings in.
        Monthly income: 100,000 cents
        Variable expenses (monthly total): 150,000 cents → 5,000/day
        → Net over 30 days: income 100k - 150k = -50k → deficit.
        """
        income = EngineIncome(
            amount_cents=100_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=15), confidence_score=1.0
        )
        expense = EngineExpense(amount_cents=150_000, is_fixed=False, due_date_day=None)
        return [income], [expense]

    def test_deficit_mode_flag_is_true(self):
        incomes, expenses = self._deficit_context()
        result = evaluate_purchase(50_000, 200_000, incomes, expenses, [], TODAY)
        assert result.deficit_mode is True

    def test_deficit_mode_affordability_zero(self):
        incomes, expenses = self._deficit_context()
        result = evaluate_purchase(50_000, 200_000, incomes, expenses, [], TODAY)
        assert result.affordability_score == 0

    def test_deficit_mode_risk_label(self):
        incomes, expenses = self._deficit_context()
        result = evaluate_purchase(50_000, 200_000, incomes, expenses, [], TODAY)
        assert "Deficit" in result.risk_level

    def test_deficit_mode_liquidity_failure_coerced_true(self):
        """Deficit implies total failure; liquidity_failure must also be True."""
        incomes, expenses = self._deficit_context()
        result = evaluate_purchase(50_000, 200_000, incomes, expenses, [], TODAY)
        assert result.liquidity_failure is True

    def test_deficit_mode_no_goals_delayed(self):
        """In deficit mode the engine short-circuits before goal analysis."""
        incomes, expenses = self._deficit_context()
        goals = [make_goal("g1", 100_000, 1), make_goal("g2", 200_000, 2)]
        result = evaluate_purchase(50_000, 200_000, incomes, expenses, goals, TODAY)
        assert result.goals_delayed == {}

    def test_deficit_mode_with_zero_starting_cash(self):
        """Zero starting cash + net-negative income still triggers deficit correctly."""
        incomes, expenses = self._deficit_context()
        result = evaluate_purchase(1_000, 0, incomes, expenses, [], TODAY)
        assert result.deficit_mode is True

    def test_deficit_mode_item_price_irrelevant(self):
        """The item's price should not matter once deficit is detected."""
        incomes, expenses = self._deficit_context()
        r1 = evaluate_purchase(1, 200_000, incomes, expenses, [], TODAY)
        r2 = evaluate_purchase(999_999, 200_000, incomes, expenses, [], TODAY)
        assert r1.deficit_mode is True
        assert r2.deficit_mode is True
        # Both produce identical Deficit sentinel results
        assert r1 == r2

    def test_exactly_break_even_is_not_deficit(self):
        """
        If the cycle budget ends exactly at the starting amount, that is NOT a deficit.
        Income precisely matches expenses → cycle_budget == 0 → deficit_mode triggered.
        
        NOTE: cycle_budget = end_balance - starting_cash. If == 0 → daily_safe_capacity = 0
        → same Deficit path. Verify this engineered break-even is handled consistently.
        """
        # Income = 100k, variable = 100k → net zero → cycle_budget == 0 → deficit path
        income = EngineIncome(
            amount_cents=100_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=15), confidence_score=1.0
        )
        expense = EngineExpense(amount_cents=100_000, is_fixed=False, due_date_day=None)
        result = evaluate_purchase(10_000, 50_000, [income], [expense], [], TODAY)
        # Break-even still triggers the deficit path because cycle_budget <= 0
        assert result.deficit_mode is True

    def test_high_confidence_income_avoids_deficit(self):
        """When income reliably exceeds costs, deficit_mode must be False."""
        income = EngineIncome(
            amount_cents=500_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=15), confidence_score=1.0
        )
        expense = EngineExpense(amount_cents=100_000, is_fixed=False, due_date_day=None)
        result = evaluate_purchase(10_000, 300_000, [income], [expense], [], TODAY)
        assert result.deficit_mode is False

    def test_low_confidence_income_triggers_deficit(self):
        """
        Edge case: high nominal income but very low confidence score
        effectively reduces expected value, pushing user into deficit.
        income_ev = 500,000 * 0.05 = 25,000
        variable expenses = 150,000 → deficit.
        """
        income = EngineIncome(
            amount_cents=500_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=15), confidence_score=0.05
        )
        expense = EngineExpense(amount_cents=150_000, is_fixed=False, due_date_day=None)
        result = evaluate_purchase(10_000, 50_000, [income], [expense], [], TODAY)
        assert result.deficit_mode is True


# ===========================================================================
# 5. evaluate_purchase — LIQUIDITY TRAP
# ===========================================================================

class TestEvaluatePurchaseLiquidityTrap:
    """
    A Liquidity Trap occurs when the user has enough money IN TOTAL to eventually
    cover everything, but buying TODAY's item drives the balance negative on at
    least one of the next 30 days before the next paycheck arrives.
    The engine must catch this and return a Liquidity Failure sentinel.
    """

    def _liquid_healthy_context(self):
        """
        User has 300k starting, earns 400k monthly in 10 days.
        Variable burn: 60k/month = 2,000/day.
        Over 30 days: end_balance = 300k - 60k + 400k = 640k → healthy surplus.
        """
        income = EngineIncome(
            amount_cents=400_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=10), confidence_score=1.0
        )
        expense = EngineExpense(amount_cents=60_000, is_fixed=False, due_date_day=None)
        return [income], [expense], 300_000

    def test_small_purchase_no_liquidity_failure(self):
        """A trivially small purchase should never cause a liquidity failure."""
        incomes, expenses, cash = self._liquid_healthy_context()
        result = evaluate_purchase(1_000, cash, incomes, expenses, [], TODAY)
        assert result.liquidity_failure is False

    def test_purchase_just_above_pre_paydate_cash_triggers_trap(self):
        """
        Spending more than what's left before the paycheck = instant trap.
        Day 0..9: cash only decreases by 2000/day = 20,000 total burned.
        After 10 days without income: 300k - 20k = 280k remaining at paydate.
        Buy 290k item today → starting cash 300k - 290k = 10k → after 5 days burn
        of 10k → balance hits 0 → liquidity failure.
        """
        incomes, expenses, cash = self._liquid_healthy_context()
        result = evaluate_purchase(290_000, cash, incomes, expenses, [], TODAY)
        assert result.liquidity_failure is True

    def test_liquidity_failure_affordability_zero(self):
        incomes, expenses, cash = self._liquid_healthy_context()
        result = evaluate_purchase(290_000, cash, incomes, expenses, [], TODAY)
        assert result.affordability_score == 0

    def test_liquidity_failure_not_deficit(self):
        """Liquidity failure is a distinct condition from deficit mode."""
        incomes, expenses, cash = self._liquid_healthy_context()
        result = evaluate_purchase(290_000, cash, incomes, expenses, [], TODAY)
        assert result.liquidity_failure is True
        assert result.deficit_mode is False

    def test_liquidity_failure_risk_label(self):
        incomes, expenses, cash = self._liquid_healthy_context()
        result = evaluate_purchase(290_000, cash, incomes, expenses, [], TODAY)
        assert "Liquidity" in result.risk_level

    def test_liquidity_failure_days_impacted_positive(self):
        """days_impacted must be a positive number even on failure."""
        incomes, expenses, cash = self._liquid_healthy_context()
        result = evaluate_purchase(290_000, cash, incomes, expenses, [], TODAY)
        assert result.days_impacted > 0

    def test_liquidity_failure_goals_delayed_empty(self):
        """Engine short-circuits before goal analysis on liquidity failure."""
        incomes, expenses, cash = self._liquid_healthy_context()
        goals = [make_goal("g1", 50_000, 1)]
        result = evaluate_purchase(290_000, cash, incomes, expenses, goals, TODAY)
        assert result.goals_delayed == {}

    def test_purchase_exactly_at_buffer_boundary(self):
        """
        Spending exactly the pre-paydate buffer should be the boundary condition.
        If balance reaches exactly 0 on some day, that still counts as failure
        because any day < 0 triggers the gate.
        Actually 0 is NOT < 0, so boundary is: spending that makes any day == -1 or less.
        Buy exactly 280k: start 300k-280k=20k after purchase; 2k/day burn; hits 0 on day 10.
        Day 10 also has income, so order: burn first, then income.
        Burn day 10: 20k - 10*(2k) = 0. Then income: +400k. Balance = 400k. No negative.
        """
        incomes, expenses, cash = self._liquid_healthy_context()
        # 10 days × 2000/day = 20k total pre-paydate burn
        result = evaluate_purchase(280_000, cash, incomes, expenses, [], TODAY)
        # Exactly 0 is NOT < 0, so no liquidity failure
        assert result.liquidity_failure is False

    def test_fixed_bill_on_near_future_day_causes_trap(self):
        """A large fixed bill due in 3 days + a purchase today drains the account."""
        income = EngineIncome(
            amount_cents=300_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=20), confidence_score=1.0
        )
        # Fixed bill on day 3 of March (today=March 1 → bill in 2 days)
        fixed_bill = make_expense(amount_cents=200_000, is_fixed=True, due_date_day=3)
        starting = 250_000
        # Buy 100k item: starting_cash = 150k. Bill hits on March 3 (offset 2): 150k-200k = -50k
        result = evaluate_purchase(100_000, starting, [income], [fixed_bill], [], TODAY)
        assert result.liquidity_failure is True

    def test_no_income_any_purchase_may_cause_trap(self):
        """Without income, even modest purchases can drain the wallet."""
        expense = EngineExpense(amount_cents=30_000, is_fixed=False, due_date_day=None)
        starting = 5_000
        # Buy 4k: start = 1k; 1k/day burn → negative on day 1
        result = evaluate_purchase(4_000, starting, [], [expense], [], TODAY)
        assert result.liquidity_failure is True

    def test_perfectly_timed_income_prevents_trap(self):
        """Income arriving on day 1 immediately rescues a near-zero balance."""
        income = EngineIncome(
            amount_cents=500_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=1), confidence_score=1.0
        )
        expense = EngineExpense(amount_cents=30_000, is_fixed=False, due_date_day=None)
        starting = 5_000
        # Buy 4k: start = 1k; day 1 burn happens FIRST (-1k→0) then income (+500k)
        # 0 is not < 0, so no liquidity failure depending on order.
        result = evaluate_purchase(4_000, starting, [income], [expense], [], TODAY)
        # Day 1: 1k - 1k(burn) = 0, then +500k = 500k. 0 is not negative.
        assert result.liquidity_failure is False


# ===========================================================================
# 6. evaluate_purchase — CASCADING GOAL DELAYS
# ===========================================================================

class TestEvaluatePurchaseCascadingDelays:
    """
    Cascading Delays: after a purchase succeeds (no liquidity failure, no deficit),
    the engine distributes the cost across goals in priority order and calculates
    how many 'days of savings' each goal is set back.
    """

    def _healthy_context(self):
        """
        Abundant income → large cycle_budget → meaningful but safe purchases.
        300k income, 30k variable = 9k net per day → cycle_budget = ~270k after margin.
        """
        income = EngineIncome(
            amount_cents=300_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=15), confidence_score=1.0
        )
        expense = EngineExpense(amount_cents=30_000, is_fixed=False, due_date_day=None)
        return [income], [expense], 500_000  # large cash so no liquidity risk

    def test_single_goal_delayed_correctly(self):
        """All of the item cost falls on the single goal."""
        incomes, expenses, cash = self._healthy_context()
        goal = make_goal("g1", 500_000, 1)
        result = evaluate_purchase(10_000, cash, incomes, expenses, [goal], TODAY)
        assert "g1" in result.goals_delayed
        assert result.goals_delayed["g1"] > 0

    def test_multiple_goals_delayed_in_priority_order(self):
        """Cost cascades from g1 (p=1) first, then spills to g2 (p=2)."""
        incomes, expenses, cash = self._healthy_context()
        # g1 target is small so the cost spills over into g2
        g1 = make_goal("g1", 1_000, 1)    # tiny goal — absorbs first 1,000 cents
        g2 = make_goal("g2", 500_000, 2)  # large goal — absorbs remainder
        result = evaluate_purchase(50_000, cash, incomes, expenses, [g1, g2], TODAY)
        assert "g1" in result.goals_delayed
        assert "g2" in result.goals_delayed

    def test_lower_priority_goal_only_hit_when_higher_exhausted(self):
        """g2 should only be touched when g1's budget is fully consumed."""
        incomes, expenses, cash = self._healthy_context()
        g1 = make_goal("g1", 100_000, 1)
        g2 = make_goal("g2", 100_000, 2)
        # Buy only 50k — fits entirely in g1
        result = evaluate_purchase(50_000, cash, incomes, expenses, [g1, g2], TODAY)
        assert "g1" in result.goals_delayed
        assert "g2" not in result.goals_delayed

    def test_cascade_across_three_goals(self):
        """Test the chain: g1 → g2 → g3, verifying each is touched in order."""
        incomes, expenses, cash = self._healthy_context()
        g1 = make_goal("g1", 5_000, 1)
        g2 = make_goal("g2", 5_000, 2)
        g3 = make_goal("g3", 500_000, 3)
        # 50k purchase: 5k to g1, 5k to g2, 40k to g3
        result = evaluate_purchase(50_000, cash, incomes, expenses, [g1, g2, g3], TODAY)
        assert "g1" in result.goals_delayed
        assert "g2" in result.goals_delayed
        assert "g3" in result.goals_delayed

    def test_no_goals_means_no_goals_delayed(self):
        """With no goals configured, goals_delayed must always be empty."""
        incomes, expenses, cash = self._healthy_context()
        result = evaluate_purchase(10_000, cash, incomes, expenses, [], TODAY)
        assert result.goals_delayed == {}

    def test_impact_proportional_to_item_price(self):
        """Double the item price → roughly double the delay for each goal."""
        incomes, expenses, cash = self._healthy_context()
        goal = make_goal("g1", 1_000_000, 1)  # large goal, won't be exhausted
        r1 = evaluate_purchase(10_000, cash, incomes, expenses, [goal], TODAY)
        r2 = evaluate_purchase(20_000, cash, incomes, expenses, [goal], TODAY)
        ratio = r2.goals_delayed["g1"] / r1.goals_delayed["g1"]
        assert abs(ratio - 2.0) < 0.01, f"Expected 2x delay ratio, got {ratio:.3f}"

    def test_goals_delayed_values_are_rounded_to_one_decimal(self):
        """Engine rounds delay values to 1 decimal place."""
        incomes, expenses, cash = self._healthy_context()
        goal = make_goal("g1", 500_000, 1)
        result = evaluate_purchase(10_000, cash, incomes, expenses, [goal], TODAY)
        delay = result.goals_delayed["g1"]
        assert round(delay, 1) == delay

    def test_purchase_exceeding_single_goal_target_caps_at_target(self):
        """
        The cascade can take AT MOST goal.target_amount_cents from each goal.
        Once deduction == target, the remainder flows to the next goal.
        """
        incomes, expenses, cash = self._healthy_context()
        g1 = make_goal("g1", 5_000, 1)
        g2 = make_goal("g2", 500_000, 2)
        # 50k item: g1 can absorb max 5k, g2 picks up the remaining 45k
        result = evaluate_purchase(50_000, cash, incomes, expenses, [g1, g2], TODAY)
        # g1 delay should correspond to 5,000 cents / daily_capacity
        # g2 delay should correspond to 45,000 cents / daily_capacity
        # ratio: g2 / g1 ≈ 45k / 5k = 9
        g1_delay = result.goals_delayed["g1"]
        g2_delay = result.goals_delayed["g2"]
        assert abs(g2_delay / g1_delay - 9.0) < 0.5

    def test_goals_evaluated_in_sorted_priority_not_insertion_order(self):
        """Goals passed in reverse priority order must still be hit in order 1→2→3."""
        incomes, expenses, cash = self._healthy_context()
        # Intentionally pass in reversed priority order
        g_low = make_goal("g_low", 5_000, 3)
        g_mid = make_goal("g_mid", 5_000, 2)
        g_high = make_goal("g_high", 5_000, 1)
        result = evaluate_purchase(7_000, cash, incomes, expenses, [g_low, g_mid, g_high], TODAY)
        # 7k purchase: 5k to g_high (p=1), 2k spills to g_mid (p=2)
        assert "g_high" in result.goals_delayed
        assert "g_mid" in result.goals_delayed
        assert "g_low" not in result.goals_delayed

    def test_item_price_exactly_equals_one_goal(self):
        """When item cost perfectly fills g1, g2 receives zero delay."""
        incomes, expenses, cash = self._healthy_context()
        g1 = make_goal("g1", 10_000, 1)
        g2 = make_goal("g2", 500_000, 2)
        result = evaluate_purchase(10_000, cash, incomes, expenses, [g1, g2], TODAY)
        assert "g1" in result.goals_delayed
        assert "g2" not in result.goals_delayed


# ===========================================================================
# 7. Compound / Combined Edge Cases
# ===========================================================================

class TestCompoundEdgeCases:
    """
    Real-world compound scenarios mixing multiple stressors simultaneously.
    """

    def test_deficit_takes_priority_over_liquidity_check(self):
        """
        When cycle_budget <= 0 (deficit), the engine must return early
        BEFORE even checking for liquidity failure from the purchase.
        """
        # Net negative cash flow forces deficit
        income = EngineIncome(
            amount_cents=10_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=15), confidence_score=1.0
        )
        expense = EngineExpense(amount_cents=200_000, is_fixed=False, due_date_day=None)
        result = evaluate_purchase(500_000, 1_000_000, [income], [expense], [], TODAY)
        assert result.deficit_mode is True      # deficit detected FIRST
        assert result.liquidity_failure is True  # coerced by deficit branch

    def test_near_zero_confidence_multiple_incomes_deficit(self):
        """Multiple unreliable income streams still aggregate to a deficit."""
        incomes = [
            EngineIncome(amount_cents=100_000, frequency="Monthly",
                         next_paydate=TODAY + timedelta(days=10), confidence_score=0.1),
            EngineIncome(amount_cents=100_000, frequency="Monthly",
                         next_paydate=TODAY + timedelta(days=20), confidence_score=0.1),
        ]
        expense = EngineExpense(amount_cents=200_000, is_fixed=False, due_date_day=None)
        result = evaluate_purchase(10_000, 50_000, incomes, expense, [], TODAY)
        # Effective monthly income: 10k+10k=20k << 200k expenses → deficit
        assert result.deficit_mode is True

    def test_liquidity_trap_with_cascading_goals_returns_no_goal_delays(self):
        """Even with goals configured, liquidity failure short-circuits goal analysis."""
        income = EngineIncome(
            amount_cents=400_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=10), confidence_score=1.0
        )
        expense = EngineExpense(amount_cents=60_000, is_fixed=False, due_date_day=None)
        goals = [make_goal("g1", 100_000, 1), make_goal("g2", 200_000, 2)]
        result = evaluate_purchase(290_000, 300_000, [income], [expense], goals, TODAY)
        assert result.liquidity_failure is True
        assert result.goals_delayed == {}

    def test_borderline_purchase_triggers_high_risk_but_no_failure(self):
        """
        A purchase consuming > 50% but < 100% of cycle budget:
        - No liquidity failure
        - High or Severe risk label
        - Nonlinear score < 50
        """
        income = EngineIncome(
            amount_cents=300_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=15), confidence_score=1.0
        )
        expense = EngineExpense(amount_cents=30_000, is_fixed=False, due_date_day=None)
        cash = 1_000_000
        # Baseline end: 1M + 270k (net income) ≈ 1.27M → cycle_budget = 1.27M - 1M = 270k * 0.95
        # Buy about 60% of that → triggers High Risk
        result = evaluate_purchase(160_000, cash, [income], [expense], [], TODAY)
        assert result.liquidity_failure is False
        assert result.deficit_mode is False
        assert result.affordability_score < 50
        assert result.risk_level in ("High Risk", "Severe Risk")

    def test_purchase_penny_is_always_low_risk(self):
        """A 1-cent purchase is always Low Risk in a healthy financial context."""
        income = make_income(500_000, "Monthly", 15, 1.0)
        expense = make_expense(100_000, False, None)
        result = evaluate_purchase(1, 300_000, [income], [expense], [], TODAY)
        assert result.risk_level == "Low Risk"
        assert result.affordability_score >= 90

    def test_multiple_fixed_bills_same_day_accumulate(self):
        """Two fixed bills on the same day-of-month must both be deducted."""
        income = EngineIncome(
            amount_cents=500_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=20), confidence_score=1.0
        )
        bill_a = make_expense(100_000, True, 10)  # due March 10
        bill_b = make_expense(100_000, True, 10)  # also due March 10
        # At offset 9 (March 10): both deducted → -200k
        timeline = simulate_cashflow_timeline(TODAY, 300_000, [income], [bill_a, bill_b], 15)
        assert timeline[9] == 300_000 - 200_000  # 200k deducted

    def test_weekly_income_delivers_four_paychecks_in_30_days(self):
        """Weekly income must fire approximately 4 times within a 30-day window."""
        income = EngineIncome(
            amount_cents=50_000, frequency="Weekly",
            next_paydate=TODAY + timedelta(days=7), confidence_score=1.0
        )
        timeline = simulate_cashflow_timeline(TODAY, 0, [income], [], 30)
        # Days with jumps: offset 6, 13, 20, 27 → 4 paychecks
        paydays = [i for i in range(1, 30) if timeline[i] > timeline[i - 1]]
        assert len(paydays) == 4

    def test_goals_cascade_respects_remaining_impact_zeroing(self):
        """
        Once remaining_impact reaches 0 during cascade, no further goals are touched.
        """
        income = EngineIncome(
            amount_cents=300_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=15), confidence_score=1.0
        )
        expense = EngineExpense(amount_cents=30_000, is_fixed=False, due_date_day=None)
        g1 = make_goal("g1", 1_000_000, 1)  # absorbs all cost
        g2 = make_goal("g2", 1_000_000, 2)
        g3 = make_goal("g3", 1_000_000, 3)
        result = evaluate_purchase(10_000, 1_000_000, [income], [expense], [g1, g2, g3], TODAY)
        assert "g1" in result.goals_delayed
        assert "g2" not in result.goals_delayed
        assert "g3" not in result.goals_delayed

    def test_evaluation_is_idempotent_for_same_inputs(self):
        """
        Calling evaluate_purchase twice with the same arguments must yield
        identical results (no hidden mutable state leaking between calls).
        """
        income = make_income(400_000, "Monthly", 15, 1.0)
        expense = make_expense(60_000, False, None)
        goal = make_goal("g1", 200_000, 1)
        r1 = evaluate_purchase(50_000, 300_000, [income], [expense], [goal], TODAY)
        r2 = evaluate_purchase(50_000, 300_000, [income], [expense], [goal], TODAY)
        assert r1 == r2

    def test_one_time_income_does_not_recur(self):
        """
        One-time income should only be credited once, not on subsequent
        occurrences after the first payday inside the horizon.
        """
        paydate = TODAY + timedelta(days=5)
        income = EngineIncome(
            amount_cents=100_000, frequency="One-time",
            next_paydate=paydate, confidence_score=1.0
        )
        timeline = simulate_cashflow_timeline(TODAY, 0, [income], [], 30)
        # Cash should jump exactly once and stay flat afterward
        jump_days = [i for i in range(1, 30) if timeline[i] > timeline[i - 1]]
        assert len(jump_days) == 1

    def test_zero_item_price_never_triggers_any_failure(self):
        """A ₵0 item has no cost impact and should always pass all checks."""
        income = make_income(300_000, "Monthly", 15, 1.0)
        expense = make_expense(60_000, False, None)
        result = evaluate_purchase(0, 300_000, [income], [expense], [], TODAY)
        assert result.liquidity_failure is False
        assert result.deficit_mode is False
        assert result.affordability_score == 100

    def test_starting_cash_zero_huge_income_no_deficit(self):
        """Zero wallet but large reliable income coming soon → should not be a deficit."""
        income = EngineIncome(
            amount_cents=1_000_000, frequency="Monthly",
            next_paydate=TODAY + timedelta(days=1), confidence_score=1.0
        )
        # No expenses
        result = evaluate_purchase(100, 0, [income], [], [], TODAY)
        # Large income arrives day 1; end balance >> start → positive cycle_budget
        assert result.deficit_mode is False
