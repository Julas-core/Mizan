"""
Insight Generator — Produces data-driven, confidence-gated home screen insights.

Rules:
  - Max 3 insights returned (more = noise = ignored app)
  - Priority: regret-based > cashflow risk > timing patterns
  - Confidence gating: n<5 skip, 5≤n<10 hedge, n≥10 confident
"""
import logging
from datetime import datetime, timezone, timedelta
from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, case, extract

from app.models.reflection import Purchase, Reflection

logger = logging.getLogger(__name__)

MIN_SAMPLES_SKIP = 5
MIN_SAMPLES_CONFIDENT = 10
MAX_INSIGHTS = 3


def _hedge(confident_text: str, hedged_text: str, sample_size: int) -> str:
    """Return confident or hedged language based on sample size."""
    if sample_size >= MIN_SAMPLES_CONFIDENT:
        return confident_text
    return hedged_text


def _insight_top_regret_category(db: Session, user_id: str) -> Optional[str]:
    """Priority 1: Regret-based insight."""
    result = (
        db.query(
            Purchase.category,
            func.count(Reflection.id).label("total"),
            func.sum(
                case(
                    (Reflection.regret_score >= 4, 1),
                    else_=0
                )
            ).label("high_regret"),
        )
        .join(Reflection, Purchase.id == Reflection.purchase_id)
        .filter(
            Purchase.user_id == user_id,
            Reflection.regret_score.isnot(None),
        )
        .group_by(Purchase.category)
        .having(func.count(Reflection.id) >= MIN_SAMPLES_SKIP)
        .order_by(
            (func.sum(case((Reflection.regret_score >= 4, 1), else_=0)) * 100 / func.count(Reflection.id)).desc()
        )
        .first()
    )

    if not result:
        return None

    category, total, high_regret = result
    rate = (high_regret or 0) / total * 100

    if rate < 40:
        return None

    return _hedge(
        f"You often regret {category} purchases — {int(rate)}% of the time.",
        f"You may be regretting {category} purchases — early data suggests {int(rate)}% regret rate.",
        total,
    )


def _insight_weekend_spending(db: Session, user_id: str) -> Optional[str]:
    """Priority 3: Timing pattern — weekend vs weekday spending."""
    thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)

    spend_data = (
        db.query(
            func.sum(
                case(
                    (extract("dow", Purchase.created_at).in_([0, 6]), Purchase.price_cents),
                    else_=0
                )
            ).label("weekend_spend"),
            func.sum(
                case(
                    (extract("dow", Purchase.created_at).not_in([0, 6]), Purchase.price_cents),
                    else_=0
                )
            ).label("weekday_spend"),
            func.count(Purchase.id).label("total"),
        )
        .filter(
            Purchase.user_id == user_id,
            Purchase.status == "BOUGHT",
            Purchase.created_at >= thirty_days_ago,
        )
        .first()
    )

    if not spend_data or (spend_data.total or 0) < MIN_SAMPLES_SKIP:
        return None

    weekend = spend_data.weekend_spend or 0
    weekday = spend_data.weekday_spend or 0
    total_spend = weekend + weekday

    if total_spend <= 0:
        return None

    weekend_pct = weekend / total_spend * 100

    # Weekend is ~29% of the week, so spending 40%+ there is notable
    if weekend_pct < 40:
        return None

    return _hedge(
        f"You tend to overspend on weekends — {int(weekend_pct)}% of your recent spending happens then.",
        f"You may be spending more on weekends — {int(weekend_pct)}% of recent spend was on Sat/Sun.",
        spend_data.total,
    )


def _insight_low_balance_timing(db: Session, user_id: str, cashflow_timeline: list[float] | None) -> Optional[str]:
    """Priority 2: Cashflow risk — which day of the month does balance dip lowest."""
    if not cashflow_timeline or len(cashflow_timeline) < 7:
        return None

    min_balance = min(cashflow_timeline)
    min_day = cashflow_timeline.index(min_balance) + 1  # 1-indexed

    # Only surface if there's a notable dip (balance drops below 30% of starting)
    start_balance = cashflow_timeline[0]
    if start_balance <= 0:
        return "You're currently in deficit — consider reviewing your fixed expenses."

    dip_ratio = min_balance / start_balance
    if dip_ratio > 0.3:
        return None

    sample_size = len(cashflow_timeline)

    return _hedge(
        f"You run low on money around day {min_day} of the month.",
        f"Your balance may dip around day {min_day} — keep an eye on spending then.",
        sample_size,
    )


def generate_insights(
    db: Session,
    user_id: str,
    cashflow_timeline: list[float] | None = None,
) -> list[str]:
    """
    Generate up to MAX_INSIGHTS data-driven insights, priority-ranked.
    
    Priority order:
      1. Regret-based (directly actionable)
      2. Cashflow risk (financial safety)
      3. Timing patterns (behavioral awareness)
    """
    insights: list[str] = []

    # Priority 1: Regret
    regret_insight = _insight_top_regret_category(db, user_id)
    if regret_insight:
        insights.append(regret_insight)

    # Priority 2: Cashflow
    if len(insights) < MAX_INSIGHTS:
        cashflow_insight = _insight_low_balance_timing(db, user_id, cashflow_timeline)
        if cashflow_insight:
            insights.append(cashflow_insight)

    # Priority 3: Weekend spending
    if len(insights) < MAX_INSIGHTS:
        weekend_insight = _insight_weekend_spending(db, user_id)
        if weekend_insight:
            insights.append(weekend_insight)

    return insights[:MAX_INSIGHTS]
