import pytest
from app.services.risk_model import compute_composite_risk, compute_behavior_penalty, _normalize_weights

def test_weight_normalization():
    # Drifted weights
    w1, w2, w3 = _normalize_weights(1.0, 0.6, 0.4)
    assert w1 == 0.5
    assert w2 == 0.3
    assert w3 == 0.2

    # Zero sum defaults
    w1, w2, w3 = _normalize_weights(0.0, 0.0, 0.0)
    assert w1 == 0.5
    assert w2 == 0.3
    assert w3 == 0.2


def test_behavior_penalty_non_linear():
    threshold = 0.5
    
    # Below threshold -> no penalty
    assert compute_behavior_penalty(0.4, threshold) == 0.0
    
    # At threshold -> no penalty
    assert compute_behavior_penalty(0.5, threshold) == 0.0
    
    # Above threshold -> quadratic
    penalty_60 = compute_behavior_penalty(0.6, threshold)
    assert round(penalty_60, 3) == 0.01  # (0.1)^2
    
    penalty_70 = compute_behavior_penalty(0.7, threshold)
    assert round(penalty_70, 3) == 0.04  # (0.2)^2


def test_behavior_penalty_smooth_gate_and_ceiling():
    # Above 0.8 -> smooth ramp
    penalty_80 = compute_behavior_penalty(0.8)
    assert round(penalty_80, 3) == 0.09  # (0.3)^2 + 0
    
    penalty_90 = compute_behavior_penalty(0.9)
    # (0.4)^2 + 0.15 * (0.1 / 0.2)
    # 0.16 + 0.15 * 0.5 = 0.16 + 0.075 = 0.235
    assert round(penalty_90, 3) == 0.235
    
    # Ceiling constraint
    penalty_100 = compute_behavior_penalty(1.0, max_penalty=0.25)
    # math: 0.25 + 0.15 = 0.4 -> ceiling is 0.25
    assert penalty_100 == 0.25


def test_composite_risk_high_regret_low_budget():
    """Behavioral Scenario: High regret + low budget -> Both spike risk"""
    risk = compute_composite_risk(
        budget_pressure=0.1,  # Can easily afford
        behavior_penalty=0.25, # Max regret
        goal_delay_impact=0.0
    )
    # 0.5 * 0.1 + 0.3 * 0.25 + 0.2 * 0
    # 0.05 + 0.075 = 0.125 -> 13 score
    assert risk == 13

    risk2 = compute_composite_risk(
        budget_pressure=0.9,  # Tight budget
        behavior_penalty=0.25, # Max regret
        goal_delay_impact=0.0
    )
    # 0.5 * 0.9 + 0.3 * 0.25 + 0.2 * 0
    # 0.45 + 0.075 = 0.525 -> 53 score
    assert risk2 == 53


def test_composite_risk_low_regret_high_goal():
    """Behavioral Scenario: Low regret + high goal impact -> moderate risk"""
    risk = compute_composite_risk(
        budget_pressure=0.2,   # Safe
        behavior_penalty=0.0,  # No regret
        goal_delay_impact=0.9  # Blows up goals
    )
    # 0.5 * 0.2 + 0.3 * 0 + 0.2 * 0.9 = 0.1 + 0.18 = 0.28 -> 28
    assert risk == 28
