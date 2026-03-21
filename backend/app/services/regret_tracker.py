"""
Regret Tracker — Connects reflection history back into the evaluation loop.

Queries past reflections per category to compute a regret rate, then produces
a behavior penalty used by the risk model. Includes cold-start bootstrapping
for new users with no history.
"""
import logging
from sqlalchemy.orm import Session
from sqlalchemy import func, case

from app.models.reflection import Purchase, Reflection

logger = logging.getLogger(__name__)

# Cold-start heuristics for categories with < MIN_REFLECTIONS
DEFAULT_REGRET: dict[str, float] = {
    "clothing": 0.5,
    "gadgets": 0.3,
    "food": 0.15,
    "entertainment": 0.4,
    "electronics": 0.35,
    "subscriptions": 0.25,
}

MIN_REFLECTIONS_FOR_REAL_DATA = 3
HIGH_REGRET_THRESHOLD = 4  # regret_score >= 4 out of 5


def get_category_regret_rate(db: Session, user_id: str, category: str) -> float:
    """
    Returns the regret rate (0.0-1.0) for a specific category.
    
    If the user has >= MIN_REFLECTIONS real reflections in this category,
    uses actual data. Otherwise falls back to DEFAULT_REGRET heuristics.
    """
    normalized_category = (category or "general").lower().strip()

    # Count reflections in this category using portable case()
    reflection_data = (
        db.query(
            func.count(Reflection.id).label("total"),
            func.sum(
                case(
                    (Reflection.regret_score >= HIGH_REGRET_THRESHOLD, 1),
                    else_=0
                )
            ).label("high_regret")
        )
        .join(Purchase, Purchase.id == Reflection.purchase_id)
        .filter(
            Purchase.user_id == user_id,
            func.lower(Purchase.category) == normalized_category,
            Reflection.regret_score.isnot(None),
        )
        .first()
    )

    total = reflection_data.total if reflection_data else 0
    
    if total >= MIN_REFLECTIONS_FOR_REAL_DATA:
        high_regret = reflection_data.high_regret or 0
        rate = high_regret / total
        logger.info(
            "User %s category '%s': real regret rate %.2f (%d/%d reflections)",
            user_id, normalized_category, rate, high_regret, total
        )
        return rate

    # Cold-start fallback
    default = DEFAULT_REGRET.get(normalized_category, 0.2)
    logger.info(
        "User %s category '%s': cold-start default %.2f (%d reflections)",
        user_id, normalized_category, default, total
    )
    return default
