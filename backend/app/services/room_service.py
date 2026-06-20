import uuid

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.room import Room
from app.models.room_member import RoomMember
from app.schemas.room import CreateRoomRequest, RoomResponse, UpdateRoomRequest


async def create_room(
    db: AsyncSession, created_by: int, data: CreateRoomRequest
) -> Room:
    room = Room(
        name=data.name,
        description=data.description,
        invite_code=str(uuid.uuid4()),
        created_by=created_by,
    )
    db.add(room)
    await db.flush()

    member = RoomMember(room_id=room.id, user_id=created_by, role="admin")
    db.add(member)
    await db.commit()
    await db.refresh(room)
    return room


async def get_room(db: AsyncSession, room_id: int) -> Room:
    result = await db.execute(
        select(Room)
        .options(selectinload(Room.members).selectinload(RoomMember.user))
        .where(Room.id == room_id)
    )
    room = result.scalar_one_or_none()
    if room is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Room not found",
        )
    return room


async def get_user_rooms(
    db: AsyncSession,
    user_id: int,
    page: int = 1,
    per_page: int = 20,
    search: str | None = None,
) -> dict:
    query = (
        select(Room)
        .join(RoomMember, RoomMember.room_id == Room.id)
        .where(RoomMember.user_id == user_id)
    )

    if search:
        query = query.where(Room.name.ilike(f"%{search}%"))

    count_query = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_query)).scalar() or 0

    query = query.order_by(Room.updated_at.desc())
    query = query.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    rooms = result.scalars().all()

    return {
        "items": [RoomResponse.model_validate(r) for r in rooms],
        "total": total,
        "page": page,
        "per_page": per_page,
    }


async def update_room(
    db: AsyncSession, room_id: int, user_id: int, data: UpdateRoomRequest
) -> Room:
    room = await get_room(db, room_id)
    await _require_admin(db, room_id, user_id)
    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(room, field, value)
    await db.commit()
    await db.refresh(room)
    return room


async def delete_room(
    db: AsyncSession, room_id: int, user_id: int
) -> None:
    room = await get_room(db, room_id)
    if room.created_by != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the room creator can delete the room",
        )
    await db.delete(room)
    await db.commit()


async def join_room(
    db: AsyncSession, user_id: int, invite_code: str
) -> Room:
    result = await db.execute(
        select(Room).where(Room.invite_code == invite_code)
    )
    room = result.scalar_one_or_none()
    if room is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid invite code",
        )

    if await is_member(db, room.id, user_id):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Already a member of this room",
        )

    member = RoomMember(room_id=room.id, user_id=user_id, role="member")
    db.add(member)
    await db.commit()
    await db.refresh(room)
    return room


async def leave_room(
    db: AsyncSession, room_id: int, user_id: int
) -> None:
    result = await db.execute(
        select(RoomMember).where(
            RoomMember.room_id == room_id,
            RoomMember.user_id == user_id,
        )
    )
    member = result.scalar_one_or_none()
    if member is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Not a member of this room",
        )
    if member.role == "admin":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Admin cannot leave. Transfer ownership or delete the room.",
        )
    await db.delete(member)
    await db.commit()


async def kick_member(
    db: AsyncSession, room_id: int, admin_id: int, user_id: int
) -> None:
    await _require_admin(db, room_id, admin_id)

    result = await db.execute(
        select(RoomMember).where(
            RoomMember.room_id == room_id,
            RoomMember.user_id == user_id,
        )
    )
    member = result.scalar_one_or_none()
    if member is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User is not a member of this room",
        )
    if member.role == "admin":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot kick the room admin",
        )
    await db.delete(member)
    await db.commit()


async def generate_invite_code(
    db: AsyncSession, room_id: int
) -> str:
    room = await get_room(db, room_id)
    room.invite_code = str(uuid.uuid4())
    await db.commit()
    return room.invite_code


async def get_room_members(
    db: AsyncSession, room_id: int
) -> list[RoomMember]:
    result = await db.execute(
        select(RoomMember)
        .options(selectinload(RoomMember.user))
        .where(RoomMember.room_id == room_id)
    )
    return list(result.scalars().all())


async def is_member(
    db: AsyncSession, room_id: int, user_id: int
) -> bool:
    result = await db.execute(
        select(RoomMember).where(
            RoomMember.room_id == room_id,
            RoomMember.user_id == user_id,
        )
    )
    return result.scalar_one_or_none() is not None


async def is_admin(
    db: AsyncSession, room_id: int, user_id: int
) -> bool:
    result = await db.execute(
        select(RoomMember).where(
            RoomMember.room_id == room_id,
            RoomMember.user_id == user_id,
            RoomMember.role == "admin",
        )
    )
    return result.scalar_one_or_none() is not None


async def _require_admin(
    db: AsyncSession, room_id: int, user_id: int
) -> None:
    if not await is_admin(db, room_id, user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin role required",
        )
