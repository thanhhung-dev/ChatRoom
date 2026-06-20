"""add feed post media

Revision ID: c7a2e4b9f031
Revises: af3c5d9e12b4
Create Date: 2026-06-20 18:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c7a2e4b9f031"
down_revision: Union[str, Sequence[str], None] = "af3c5d9e12b4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "feed_post_media",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("post_id", sa.Integer(), nullable=False),
        sa.Column("media_url", sa.String(length=500), nullable=False),
        sa.Column("media_name", sa.String(length=255), nullable=True),
        sa.Column("media_type", sa.String(length=20), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["post_id"], ["feed_posts.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_feed_post_media_id"), "feed_post_media", ["id"], unique=False)
    op.execute(
        """
        INSERT INTO feed_post_media (post_id, media_url, media_name, media_type, sort_order)
        SELECT id, media_url, media_name, media_type, 0
        FROM feed_posts
        WHERE media_url IS NOT NULL
        """
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_feed_post_media_id"), table_name="feed_post_media")
    op.drop_table("feed_post_media")
