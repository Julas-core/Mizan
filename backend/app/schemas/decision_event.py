from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class DecisionEventCreate(BaseModel):
    event_type: str = Field(..., min_length=1, max_length=64)
    purchase_id: str | None = None
    verdict: str | None = Field(default=None, max_length=64)
    dominant_factor: str | None = Field(default=None, max_length=64)
    risk_level: str | None = Field(default=None, max_length=32)
    category: str | None = Field(default=None, max_length=100)
    amount_band: str | None = Field(default=None, max_length=32)
    recommended_action: str | None = Field(default=None, max_length=32)
    user_action: str | None = Field(default=None, max_length=32)
    overrode_recommendation: bool | None = None
    feedback_helpful: bool | None = None
    metadata_json: dict[str, Any] | None = None


class DecisionEventResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    purchase_id: str | None = None
    event_type: str
    verdict: str | None = None
    dominant_factor: str | None = None
    risk_level: str | None = None
    category: str | None = None
    amount_band: str | None = None
    recommended_action: str | None = None
    user_action: str | None = None
    overrode_recommendation: bool | None = None
    feedback_helpful: bool | None = None
    metadata_json: dict[str, Any] | None = None
    created_at: datetime


class DecisionQualityBreakdown(BaseModel):
    key: str
    total: int
    accepted_count: int
    overridden_count: int
    acceptance_rate: float
    override_rate: float
    confidence: str


class DecisionQualitySummary(BaseModel):
    lookback_days: int
    min_sample: int
    total_shown: int
    accepted_count: int
    overridden_count: int
    acceptance_rate: float
    override_rate: float
    helpful_rate: float
    follow_regret_rate: float
    override_regret_rate: float
    follow_pressure_rate: float
    override_pressure_rate: float
    breakdown_by_factor: list[DecisionQualityBreakdown]
    breakdown_by_verdict: list[DecisionQualityBreakdown]


class DecisionQualityTrendPoint(BaseModel):
    bucket: str
    summary: DecisionQualitySummary


class DecisionQualityTrendsResponse(BaseModel):
    lookback_days: int
    min_sample: int
    weekly: list[DecisionQualityTrendPoint]
    by_category: list[DecisionQualityTrendPoint]
