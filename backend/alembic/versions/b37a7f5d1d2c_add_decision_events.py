"""add decision events table

Revision ID: b37a7f5d1d2c
Revises: 6de24b6e387e
Create Date: 2026-03-23 18:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "b37a7f5d1d2c"
down_revision: Union[str, None] = "6de24b6e387e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "decision_events",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("purchase_id", sa.String(), nullable=True),
        sa.Column("event_type", sa.String(), nullable=False),
        sa.Column("verdict", sa.String(), nullable=True),
        sa.Column("dominant_factor", sa.String(), nullable=True),
        sa.Column("risk_level", sa.String(), nullable=True),
        sa.Column("category", sa.String(), nullable=True),
        sa.Column("amount_band", sa.String(), nullable=True),
        sa.Column("recommended_action", sa.String(), nullable=True),
        sa.Column("user_action", sa.String(), nullable=True),
        sa.Column("overrode_recommendation", sa.Boolean(), nullable=True),
        sa.Column("feedback_helpful", sa.Boolean(), nullable=True),
        sa.Column("metadata_json", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.ForeignKeyConstraint(["purchase_id"], ["purchases.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_index(op.f("ix_decision_events_id"), "decision_events", ["id"], unique=False)
    op.create_index(op.f("ix_decision_events_user_id"), "decision_events", ["user_id"], unique=False)
    op.create_index(op.f("ix_decision_events_purchase_id"), "decision_events", ["purchase_id"], unique=False)
    op.create_index(op.f("ix_decision_events_event_type"), "decision_events", ["event_type"], unique=False)
    op.create_index(op.f("ix_decision_events_verdict"), "decision_events", ["verdict"], unique=False)
    op.create_index(op.f("ix_decision_events_dominant_factor"), "decision_events", ["dominant_factor"], unique=False)

    op.create_index(
        "idx_decision_events_user_created",
        "decision_events",
        ["user_id", "created_at"],
        unique=False,
    )
    op.create_index("idx_decision_events_type", "decision_events", ["event_type"], unique=False)
    op.create_index("idx_decision_events_verdict", "decision_events", ["verdict"], unique=False)
    op.create_index(
        "idx_decision_events_dominant_factor",
        "decision_events",
        ["dominant_factor"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("idx_decision_events_dominant_factor", table_name="decision_events")
    op.drop_index("idx_decision_events_verdict", table_name="decision_events")
    op.drop_index("idx_decision_events_type", table_name="decision_events")
    op.drop_index("idx_decision_events_user_created", table_name="decision_events")

    op.drop_index(op.f("ix_decision_events_dominant_factor"), table_name="decision_events")
    op.drop_index(op.f("ix_decision_events_verdict"), table_name="decision_events")
    op.drop_index(op.f("ix_decision_events_event_type"), table_name="decision_events")
    op.drop_index(op.f("ix_decision_events_purchase_id"), table_name="decision_events")
    op.drop_index(op.f("ix_decision_events_user_id"), table_name="decision_events")
    op.drop_index(op.f("ix_decision_events_id"), table_name="decision_events")

    op.drop_table("decision_events")
