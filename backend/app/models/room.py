import uuid

from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class Room(Base):
    __tablename__ = "rooms"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=True, default="")
    invite_code: Mapped[str] = mapped_column(
        String(36), unique=True, nullable=False, default=lambda: str(uuid.uuid4())
    )
    created_by: Mapped[int] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    created_at: Mapped[str] = mapped_column(
        DateTime, server_default=func.now()
    )
    updated_at: Mapped[str] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )

    members = relationship("RoomMember", back_populates="room", cascade="all, delete-orphan")
    creator = relationship("User", foreign_keys=[created_by])
