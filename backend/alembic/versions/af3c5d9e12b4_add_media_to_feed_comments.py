"""add media to feed comments

Revision ID: af3c5d9e12b4
Revises: 9b7e1f4d2c6a
Create Date: 2026-06-20 09:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "af3c5d9e12b4"
down_revision: Union[str, Sequence[str], None] = "9b7e1f4d2c6a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("feed_comments", sa.Column("media_url", sa.String(length=500), nullable=True))
    op.add_column("feed_comments", sa.Column("media_name", sa.String(length=255), nullable=True))
    op.add_column("feed_comments", sa.Column("media_type", sa.String(length=20), nullable=True))


def downgrade() -> None:
    op.drop_column("feed_comments", "media_type")
    op.drop_column("feed_comments", "media_name")
    op.drop_column("feed_comments", "media_url")
