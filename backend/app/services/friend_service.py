from __future__ import annotations

import json

from fastapi import HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.friendship import FriendRequest, Friendship
from app.models.room import Room
from app.models.room_member import RoomMember
from app.models.user import User
from app.services import room_service
from app.ws.manager import manager


def _pair(a: int, b: int) -> tuple[int, int]:
    return (a, b) if a < b else (b, a)


async def search_users(db: AsyncSession, current_user_id: int, query: str) -> list[User]:
    pattern = f"%{query.strip()}%"
    result = await db.execute(
        select(User)
        .where(User.id != current_user_id)
        .where(or_(User.username.ilike(pattern), User.display_name.ilike(pattern)))
        .limit(20)
    )
    return list(result.scalars())


async def send_request(db: AsyncSession, requester_id: int, username: str) -> FriendRequest:
    result = await db.execute(select(User).where(User.username == username))
    receiver = result.scalar_one_or_none()
    if receiver is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if receiver.id == requester_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot add yourself")

    low, high = _pair(requester_id, receiver.id)
    existing_friend = await db.execute(
        select(Friendship).where(Friendship.user_low_id == low, Friendship.user_high_id == high)
    )
    if existing_friend.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Already friends")

    existing_request = await db.execute(
        select(FriendRequest).where(
            or_(
                (FriendRequest.requester_id == requester_id)
                & (FriendRequest.receiver_id == receiver.id),
                (FriendRequest.requester_id == receiver.id)
                & (FriendRequest.receiver_id == requester_id),
            )
        )
    )
    request = existing_request.scalar_one_or_none()
    if request and request.status == "pending":
        return request

    request = FriendRequest(requester_id=requester_id, receiver_id=receiver.id, status="pending")
    db.add(request)
    await db.commit()
    saved = await get_request(db, request.id)
    await manager.send_personal(
        receiver.id,
        json.dumps(
            {
                "type": "friend_request",
                "payload": {
                    "request_id": saved.id,
                    "sender_id": requester_id,
                    "sender_username": saved.requester.username,
                    "sender_display_name": saved.requester.display_name,
                },
            }
        ),
    )
    return saved


async def list_incoming(db: AsyncSession, user_id: int) -> list[FriendRequest]:
    result = await db.execute(
        select(FriendRequest)
        .options(selectinload(FriendRequest.requester), selectinload(FriendRequest.receiver))
        .where(FriendRequest.receiver_id == user_id, FriendRequest.status == "pending")
        .order_by(FriendRequest.created_at.desc())
    )
    return list(result.scalars())


async def get_request(db: AsyncSession, request_id: int) -> FriendRequest:
    result = await db.execute(
        select(FriendRequest)
        .options(selectinload(FriendRequest.requester), selectinload(FriendRequest.receiver))
        .where(FriendRequest.id == request_id)
    )
    request = result.scalar_one_or_none()
    if request is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Request not found")
    return request


async def respond_request(
    db: AsyncSession, current_user_id: int, request_id: int, accept: bool
) -> Friendship | None:
    request = await get_request(db, request_id)
    if request.receiver_id != current_user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your request")
    if request.status != "pending":
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Request already handled")

    request.status = "accepted" if accept else "rejected"
    if not accept:
        await db.commit()
        await manager.send_personal(
            request.requester_id,
            json.dumps(
                {
                    "type": "friend_rejected",
                    "payload": {
                        "request_id": request.id,
                        "sender_id": request.receiver_id,
                        "sender_username": request.receiver.username,
                        "sender_display_name": request.receiver.display_name,
                    },
                }
            ),
        )
        return None

    low, high = _pair(request.requester_id, request.receiver_id)
    room = Room(name=f"{request.requester.username} & {request.receiver.username}", created_by=current_user_id)
    db.add(room)
    await db.flush()
    db.add(RoomMember(room_id=room.id, user_id=request.requester_id, role="member"))
    db.add(RoomMember(room_id=room.id, user_id=request.receiver_id, role="member"))
    friendship = Friendship(user_low_id=low, user_high_id=high, room_id=room.id)
    db.add(friendship)
    await db.commit()
    await manager.send_personal(
        request.requester_id,
        json.dumps(
            {
                "type": "friend_accepted",
                "payload": {
                    "request_id": request.id,
                    "room_id": room.id,
                    "sender_id": request.receiver_id,
                    "sender_username": request.receiver.username,
                    "sender_display_name": request.receiver.display_name,
                },
            }
        ),
    )
    return await get_friendship(db, friendship.id)


async def get_friendship(db: AsyncSession, friendship_id: int) -> Friendship:
    result = await db.execute(
        select(Friendship)
        .options(
            selectinload(Friendship.user_low),
            selectinload(Friendship.user_high),
            selectinload(Friendship.room),
        )
        .where(Friendship.id == friendship_id)
    )
    friendship = result.scalar_one()
    return friendship


async def list_friends(db: AsyncSession, user_id: int) -> list[Friendship]:
    result = await db.execute(
        select(Friendship)
        .options(
            selectinload(Friendship.user_low),
            selectinload(Friendship.user_high),
            selectinload(Friendship.room),
        )
        .where(or_(Friendship.user_low_id == user_id, Friendship.user_high_id == user_id))
        .order_by(Friendship.created_at.desc())
    )
    return list(result.scalars())


async def delete_friendship(db: AsyncSession, current_user_id: int, friendship_id: int) -> None:
    friendship = await get_friendship(db, friendship_id)
    if current_user_id not in {friendship.user_low_id, friendship.user_high_id}:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your friendship")

    other_user = (
        friendship.user_high
        if friendship.user_low_id == current_user_id
        else friendship.user_low
    )
    current_user = (
        friendship.user_low
        if friendship.user_low_id == current_user_id
        else friendship.user_high
    )
    room = friendship.room

    await db.delete(friendship)
    if room is not None:
        await db.delete(room)
    await db.commit()

    await manager.send_personal(
        other_user.id,
        json.dumps(
            {
                "type": "friend_removed",
                "payload": {
                    "friendship_id": friendship_id,
                    "sender_id": current_user.id,
                    "sender_username": current_user.username,
                    "sender_display_name": current_user.display_name,
                },
            }
        ),
    )
