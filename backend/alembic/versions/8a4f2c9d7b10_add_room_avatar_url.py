"""add room avatar url

Revision ID: 8a4f2c9d7b10
Revises: ff0ea92d1d20
Create Date: 2026-06-07 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "8a4f2c9d7b10"
down_revision: Union[str, Sequence[str], None] = "ff0ea92d1d20"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("rooms", sa.Column("avatar_url", sa.String(length=500), nullable=True))


def downgrade() -> None:
    op.drop_column("rooms", "avatar_url")
