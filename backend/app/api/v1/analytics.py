from collections import defaultdict
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.orm import Session

from app.api import dependencies
from app.api.dependencies import get_current_user, require_same_user
from app.models.decision_event import DecisionEvent
from app.models.reflection import Reflection
from app.models.user import User as UserModel
from app.schemas.decision_event import (
    DecisionEventCreate,
    DecisionEventResponse,
    DecisionQualityBreakdown,
    DecisionQualitySummary,
    DecisionQualityTrendPoint,
    DecisionQualityTrendsResponse,
)
from app.services.idempotency_service import get_idempotent_payload, persist_idempotent_payload

router = APIRouter()


def _round_rate(numerator: int, denominator: int) -> float:
    if denominator <= 0:
        return 0.0
    return round((numerator / denominator) * 100.0, 2)


def _confidence_for_sample(total: int, min_sample: int) -> str:
    return "stable" if total >= min_sample else "low_sample"


def _build_breakdown(events: list[DecisionEvent], key_attr: str, min_sample: int) -> list[DecisionQualityBreakdown]:
    grouped: dict[str, dict[str, int]] = defaultdict(lambda: {"total": 0, "accepted": 0, "overridden": 0})

    for event in events:
        key = getattr(event, key_attr) or "unknown"
        group = grouped[key]
        group["total"] += 1
        if event.overrode_recommendation is True:
            group["overridden"] += 1
        elif event.overrode_recommendation is False:
            group["accepted"] += 1

    breakdown = []
    for key, values in grouped.items():
        total = values["total"]
        accepted = values["accepted"]
        overridden = values["overridden"]
        breakdown.append(
            DecisionQualityBreakdown(
                key=key,
                total=total,
                accepted_count=accepted,
                overridden_count=overridden,
                acceptance_rate=_round_rate(accepted, total),
                override_rate=_round_rate(overridden, total),
                confidence=_confidence_for_sample(total, min_sample),
            )
        )

    breakdown.sort(key=lambda x: x.total, reverse=True)
    return breakdown


def _build_quality_summary(
    lookback_days: int,
    min_sample: int,
    shown_events: list[DecisionEvent],
    action_events: list[DecisionEvent],
    feedback_events: list[DecisionEvent],
    reflections: list[Reflection],
) -> DecisionQualitySummary:
    purchase_actions: dict[str, DecisionEvent] = {}
    for event in sorted(action_events, key=lambda e: e.created_at or datetime.min.replace(tzinfo=timezone.utc)):
        if event.purchase_id:
            purchase_actions[event.purchase_id] = event

    reflection_by_purchase: dict[str, list[Reflection]] = defaultdict(list)
    for reflection in reflections:
        reflection_by_purchase[reflection.purchase_id].append(reflection)

    follow_with_reflection = 0
    follow_regret = 0
    follow_pressure = 0
    override_with_reflection = 0
    override_regret = 0
    override_pressure = 0

    for purchase_id, action_event in purchase_actions.items():
        linked_reflections = reflection_by_purchase.get(purchase_id, [])
        if not linked_reflections:
            continue

        has_regret = any((r.regret_score or 0) >= 4 for r in linked_reflections)
        has_pressure = any(r.felt_financial_pressure is True for r in linked_reflections)

        if action_event.overrode_recommendation is True:
            override_with_reflection += 1
            if has_regret:
                override_regret += 1
            if has_pressure:
                override_pressure += 1
        elif action_event.overrode_recommendation is False:
            follow_with_reflection += 1
            if has_regret:
                follow_regret += 1
            if has_pressure:
                follow_pressure += 1

    total_shown = len(shown_events)
    accepted_count = sum(1 for e in action_events if e.overrode_recommendation is False)
    overridden_count = sum(1 for e in action_events if e.overrode_recommendation is True)
    helpful_count = sum(1 for e in feedback_events if e.feedback_helpful is True)

    return DecisionQualitySummary(
        lookback_days=lookback_days,
        min_sample=min_sample,
        total_shown=total_shown,
        accepted_count=accepted_count,
        overridden_count=overridden_count,
        acceptance_rate=_round_rate(accepted_count, total_shown),
        override_rate=_round_rate(overridden_count, total_shown),
        helpful_rate=_round_rate(helpful_count, len(feedback_events)),
        follow_regret_rate=_round_rate(follow_regret, follow_with_reflection),
        override_regret_rate=_round_rate(override_regret, override_with_reflection),
        follow_pressure_rate=_round_rate(follow_pressure, follow_with_reflection),
        override_pressure_rate=_round_rate(override_pressure, override_with_reflection),
        breakdown_by_factor=_build_breakdown(shown_events, "dominant_factor", min_sample),
        breakdown_by_verdict=_build_breakdown(shown_events, "verdict", min_sample),
    )


def _iso_week_bucket(event: DecisionEvent) -> str:
    timestamp = event.created_at or datetime.min.replace(tzinfo=timezone.utc)
    iso = timestamp.isocalendar()
    return f"{iso.year}-W{iso.week:02d}"


@router.post("/{user_id}/decision-events", response_model=DecisionEventResponse)
def create_decision_event(
    user_id: str,
    payload: DecisionEventCreate,
    db: Session = Depends(dependencies.get_db),
    current_user=Depends(get_current_user),
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
):
    require_same_user(current_user, user_id)
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    endpoint_key = f"analytics.decision-events:{user_id}"
    if idempotency_key:
        replay_payload = get_idempotent_payload(db, endpoint_key, idempotency_key)
        if replay_payload:
            return DecisionEventResponse(**replay_payload)

    event = DecisionEvent(
        user_id=user_id,
        purchase_id=payload.purchase_id,
        event_type=payload.event_type,
        verdict=payload.verdict,
        dominant_factor=payload.dominant_factor,
        risk_level=payload.risk_level,
        category=payload.category,
        amount_band=payload.amount_band,
        recommended_action=payload.recommended_action,
        user_action=payload.user_action,
        overrode_recommendation=payload.overrode_recommendation,
        feedback_helpful=payload.feedback_helpful,
        metadata_json=payload.metadata_json,
    )
    db.add(event)
    db.flush()

    response_payload = DecisionEventResponse.model_validate(event)

    if idempotency_key:
        persist_idempotent_payload(
            db=db,
            endpoint=endpoint_key,
            idempotency_key=idempotency_key,
            payload=response_payload.model_dump(mode="json"),
            resource_type="decision_event",
            resource_id=event.id,
        )

    db.commit()
    db.refresh(event)
    return event


@router.get("/{user_id}/decision-quality", response_model=DecisionQualitySummary)
def get_decision_quality(
    user_id: str,
    lookback_days: int = 30,
    min_sample: int = 5,
    db: Session = Depends(dependencies.get_db),
    current_user=Depends(get_current_user),
):
    require_same_user(current_user, user_id)
    if lookback_days <= 0:
        raise HTTPException(status_code=400, detail="lookback_days must be greater than zero")
    if min_sample <= 0:
        raise HTTPException(status_code=400, detail="min_sample must be greater than zero")

    since = datetime.now(timezone.utc) - timedelta(days=lookback_days)

    shown_events = (
        db.query(DecisionEvent)
        .filter(
            DecisionEvent.user_id == user_id,
            DecisionEvent.event_type == "verdict_shown",
            DecisionEvent.created_at >= since,
        )
        .all()
    )
    action_events = (
        db.query(DecisionEvent)
        .filter(
            DecisionEvent.user_id == user_id,
            DecisionEvent.event_type == "action_selected",
            DecisionEvent.created_at >= since,
        )
        .all()
    )
    feedback_events = (
        db.query(DecisionEvent)
        .filter(
            DecisionEvent.user_id == user_id,
            DecisionEvent.event_type == "feedback_submitted",
            DecisionEvent.created_at >= since,
            DecisionEvent.feedback_helpful.isnot(None),
        )
        .all()
    )

    purchase_ids = list({e.purchase_id for e in action_events if e.purchase_id})
    reflections = []
    if purchase_ids:
        reflections = (
            db.query(Reflection)
            .filter(Reflection.user_id == user_id, Reflection.purchase_id.in_(purchase_ids))
            .all()
        )

    return _build_quality_summary(
        lookback_days=lookback_days,
        min_sample=min_sample,
        shown_events=shown_events,
        action_events=action_events,
        feedback_events=feedback_events,
        reflections=reflections,
    )


@router.get("/{user_id}/decision-quality/trends", response_model=DecisionQualityTrendsResponse)
def get_decision_quality_trends(
    user_id: str,
    lookback_days: int = 90,
    min_sample: int = 5,
    db: Session = Depends(dependencies.get_db),
    current_user=Depends(get_current_user),
):
    require_same_user(current_user, user_id)
    if lookback_days <= 0:
        raise HTTPException(status_code=400, detail="lookback_days must be greater than zero")
    if min_sample <= 0:
        raise HTTPException(status_code=400, detail="min_sample must be greater than zero")

    since = datetime.now(timezone.utc) - timedelta(days=lookback_days)

    events = (
        db.query(DecisionEvent)
        .filter(DecisionEvent.user_id == user_id, DecisionEvent.created_at >= since)
        .all()
    )

    action_events = [e for e in events if e.event_type == "action_selected" and e.purchase_id]
    purchase_ids = list({e.purchase_id for e in action_events if e.purchase_id})
    reflections = []
    if purchase_ids:
        reflections = (
            db.query(Reflection)
            .filter(Reflection.user_id == user_id, Reflection.purchase_id.in_(purchase_ids))
            .all()
        )

    weekly_buckets: dict[str, list[DecisionEvent]] = defaultdict(list)
    for event in events:
        weekly_buckets[_iso_week_bucket(event)].append(event)

    weekly_points: list[DecisionQualityTrendPoint] = []
    for bucket, bucket_events in sorted(weekly_buckets.items()):
        bucket_shown = [e for e in bucket_events if e.event_type == "verdict_shown"]
        bucket_actions = [e for e in bucket_events if e.event_type == "action_selected"]
        bucket_feedback = [
            e for e in bucket_events if e.event_type == "feedback_submitted" and e.feedback_helpful is not None
        ]
        bucket_purchase_ids = {e.purchase_id for e in bucket_actions if e.purchase_id}
        bucket_reflections = [r for r in reflections if r.purchase_id in bucket_purchase_ids]
        summary = _build_quality_summary(
            lookback_days=lookback_days,
            min_sample=min_sample,
            shown_events=bucket_shown,
            action_events=bucket_actions,
            feedback_events=bucket_feedback,
            reflections=bucket_reflections,
        )
        weekly_points.append(DecisionQualityTrendPoint(bucket=bucket, summary=summary))

    category_buckets: dict[str, list[DecisionEvent]] = defaultdict(list)
    for event in events:
        if event.category:
            category_buckets[event.category].append(event)

    category_points: list[DecisionQualityTrendPoint] = []
    for bucket, bucket_events in sorted(category_buckets.items()):
        bucket_shown = [e for e in bucket_events if e.event_type == "verdict_shown"]
        bucket_actions = [e for e in bucket_events if e.event_type == "action_selected"]
        bucket_feedback = [
            e for e in bucket_events if e.event_type == "feedback_submitted" and e.feedback_helpful is not None
        ]
        bucket_purchase_ids = {e.purchase_id for e in bucket_actions if e.purchase_id}
        bucket_reflections = [r for r in reflections if r.purchase_id in bucket_purchase_ids]
        summary = _build_quality_summary(
            lookback_days=lookback_days,
            min_sample=min_sample,
            shown_events=bucket_shown,
            action_events=bucket_actions,
            feedback_events=bucket_feedback,
            reflections=bucket_reflections,
        )
        category_points.append(DecisionQualityTrendPoint(bucket=bucket, summary=summary))

    return DecisionQualityTrendsResponse(
        lookback_days=lookback_days,
        min_sample=min_sample,
        weekly=weekly_points,
        by_category=category_points,
    )
