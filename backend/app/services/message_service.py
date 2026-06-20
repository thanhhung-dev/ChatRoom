from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.message import Message
from app.models.room_member import RoomMember
from app.schemas.message import MessageResponse
from app.ws.manager import manager
from app.ws.protocol import NewMessagePayload, ServerEvent, build_server_message


async def create_message(
    db: AsyncSession,
    *,
    room_id: int,
    user_id: int,
    content: str | None = None,
    message_type: str = "text",
    file_url: str | None = None,
    file_name: str | None = None,
) -> Message:
    await _require_member(db, room_id, user_id)

    message = Message(
        room_id=room_id,
        user_id=user_id,
        content=content,
        message_type=message_type,
        file_url=file_url,
        file_name=file_name,
    )
    db.add(message)
    await db.flush()
    message_id = message.id
    await db.commit()
    result = await db.execute(
        select(Message)
        .options(selectinload(Message.user))
        .where(Message.id == message_id)
    )
    message = result.scalar_one()
    await broadcast_message(message)
    return message


async def broadcast_message(message: Message) -> None:
    if message.user is None:
        return
    await manager.broadcast(
        message.room_id,
        build_server_message(
            ServerEvent.NEW_MESSAGE,
            NewMessagePayload(
                room_id=message.room_id,
                message_id=message.id,
                sender_id=message.user_id,
                sender_username=message.user.username,
                content=message.content,
                content_type=message.message_type,
                created_at=message.created_at,
                file_url=message.file_url,
                file_name=message.file_name,
            ),
        ),
    )


async def get_messages(
    db: AsyncSession,
    room_id: int,
    user_id: int,
    page: int = 1,
    per_page: int = 50,
    before_id: int | None = None,
    search: str | None = None,
) -> dict:
    await _require_member(db, room_id, user_id)

    query = (
        select(Message)
        .options(selectinload(Message.user))
        .where(Message.room_id == room_id)
    )

    if before_id:
        query = query.where(Message.id < before_id)

    if search:
        query = query.where(Message.content.ilike(f"%{search}%"))

    count_query = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_query)).scalar() or 0

    query = query.order_by(Message.id.desc())
    query = query.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    messages = result.scalars().all()

    return {
        "items": [MessageResponse.model_validate(m) for m in messages],
        "total": total,
        "page": page,
        "per_page": per_page,
    }


async def get_messages_after(
    db: AsyncSession, room_id: int, after_id: int
) -> list[Message]:
    result = await db.execute(
        select(Message)
        .options(selectinload(Message.user))
        .where(Message.room_id == room_id, Message.id > after_id)
        .order_by(Message.id.asc())
    )
    return list(result.scalars().all())


async def update_status(
    db: AsyncSession, message_id: int, new_status: str
) -> None:
    result = await db.execute(
        select(Message).where(Message.id == message_id)
    )
    message = result.scalar_one_or_none()
    if message is None:
        return
    message.status = new_status
    await db.commit()


async def _require_member(
    db: AsyncSession, room_id: int, user_id: int
) -> None:
    result = await db.execute(
        select(RoomMember).where(
            RoomMember.room_id == room_id,
            RoomMember.user_id == user_id,
        )
    )
    if result.scalar_one_or_none() is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this room",
        )
