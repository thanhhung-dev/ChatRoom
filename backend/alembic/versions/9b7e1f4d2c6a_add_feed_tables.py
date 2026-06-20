"""add feed tables

Revision ID: 9b7e1f4d2c6a
Revises: 2d4b0a7c9e11
Create Date: 2026-06-19 12:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "9b7e1f4d2c6a"
down_revision: Union[str, Sequence[str], None] = "2d4b0a7c9e11"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "feed_posts",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("content", sa.Text(), nullable=True),
        sa.Column("media_url", sa.String(length=500), nullable=True),
        sa.Column("media_name", sa.String(length=255), nullable=True),
        sa.Column("media_type", sa.String(length=20), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_feed_posts_id"), "feed_posts", ["id"], unique=False)

    op.create_table(
        "feed_reactions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("post_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("reaction", sa.String(length=12), nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["post_id"], ["feed_posts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("post_id", "user_id", name="uq_feed_reaction_user"),
    )
    op.create_index(op.f("ix_feed_reactions_id"), "feed_reactions", ["id"], unique=False)

    op.create_table(
        "feed_comments",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("post_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["post_id"], ["feed_posts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_feed_comments_id"), "feed_comments", ["id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_feed_comments_id"), table_name="feed_comments")
    op.drop_table("feed_comments")
    op.drop_index(op.f("ix_feed_reactions_id"), table_name="feed_reactions")
    op.drop_table("feed_reactions")
    op.drop_index(op.f("ix_feed_posts_id"), table_name="feed_posts")
    op.drop_table("feed_posts")
