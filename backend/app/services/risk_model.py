"""
Risk Model v2 — Composite weighted scoring with non-linear penalties.

All functions are pure: data in → result out. No DB access.
"""
import logging

logger = logging.getLogger(__name__)


def _normalize_weights(w_afford: float, w_behave: float, w_goal: float) -> tuple[float, float, float]:
    """Normalize weights so they always sum to 1.0, regardless of config drift."""
    total = w_afford + w_behave + w_goal
    if total <= 0:
        return (0.5, 0.3, 0.2)  # fallback to defaults
    return (w_afford / total, w_behave / total, w_goal / total)


def compute_behavior_penalty(
    regret_rate: float,
    threshold: float = 0.5,
    max_penalty: float = 0.25,
) -> float:
    """
    Non-linear penalty based on category regret history.
    
    - Quadratic ramp above threshold
    - Smooth gate above 0.8 (no snap)
    - Clamped to max_penalty so behavior never dominates
    """
    if regret_rate <= threshold:
        return 0.0

    penalty = (regret_rate - threshold) ** 2

    # Smooth ramp above 0.8 — not a hard snap
    if regret_rate > 0.8:
        penalty += 0.15 * (regret_rate - 0.8) / 0.2

    return min(penalty, max_penalty)


def compute_composite_risk(
    budget_pressure: float,
    behavior_penalty: float,
    goal_delay_impact: float,
    w_afford: float = 0.5,
    w_behave: float = 0.3,
    w_goal: float = 0.2,
) -> int:
    """
    Compute a 0-100 risk score from three normalized signals.
    
    Args:
        budget_pressure: 0.0 (no pressure) to 1.0 (cannot afford)
        behavior_penalty: 0.0 (no regret history) to max_penalty
        goal_delay_impact: 0.0 (no delay) to 1.0 (severe delay)
    
    Returns:
        Integer risk score 0-100 (higher = riskier)
    """
    w_a, w_b, w_g = _normalize_weights(w_afford, w_behave, w_goal)

    raw_risk = (
        w_a * min(budget_pressure, 1.0) +
        w_b * min(behavior_penalty, 1.0) +
        w_g * min(goal_delay_impact, 1.0)
    )

    return int(round(min(max(raw_risk * 100, 0), 100)))


def explain_risk(
    budget_pressure: float,
    behavior_penalty: float,
    goal_delay_impact: float,
    final_score: int,
    behavior_explanation: str = "",
) -> dict:
    """
    Returns a structured breakdown dict for the API response.
    """
    return {
        "affordability": round(budget_pressure, 3),
        "behavior": round(behavior_penalty, 3),
        "goal_impact": round(goal_delay_impact, 3),
        "final_score": final_score,
        "behavior_explanation": behavior_explanation,
    }
