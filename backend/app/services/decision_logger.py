"""
Decision Audit Logger — Structured logging for every evaluation.

Captures the full signal chain (inputs → scores → decision) so we can later
correlate with reflection outcomes to prove the model's effectiveness.
"""
import logging
import json
from datetime import datetime, timezone

logger = logging.getLogger("mizan.decisions")


def log_evaluation(
    user_id: str,
    item_name: str,
    price_cents: int,
    category: str,
    budget_pressure: float,
    behavior_penalty: float,
    goal_delay_impact: float,
    regret_rate: float,
    final_risk_score: int,
    risk_level: str,
    affordability_score: int,
    goal_delays: dict,
) -> None:
    """
    Log a structured decision audit entry.
    
    This enables later analysis like:
    "Users who ignored high-risk warnings had higher regret rates"
    """
    audit_entry = {
        "event": "purchase_evaluation",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "user_id": user_id,
        "item": item_name,
        "price_cents": price_cents,
        "category": category,
        "signals": {
            "budget_pressure": round(budget_pressure, 4),
            "behavior_penalty": round(behavior_penalty, 4),
            "goal_delay_impact": round(goal_delay_impact, 4),
            "regret_rate": round(regret_rate, 4),
        },
        "result": {
            "risk_score": final_risk_score,
            "risk_level": risk_level,
            "affordability_score": affordability_score,
            "goal_delays": goal_delays,
        },
    }

    logger.info("DECISION_AUDIT: %s", json.dumps(audit_entry))
