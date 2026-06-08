from __future__ import annotations

import json
import logging
from datetime import datetime

from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_token
from app.dependencies import get_db
from app.models.message import Message
from app.models.room_member import RoomMember
from app.models.user import User
from app.services.presence_services import PresenceService
from app.ws.manager import manager
from app.ws.protocol import (
    ClientEvent,
    JoinRoomPayload,
    LeaveRoomPayload,
    MarkReadPayload,
    NewMessagePayload,
    PongPayload,
    SendMessagePayload,
    ServerEvent,
    SyncMessagesPayload,
    SyncResponsePayload,
    TypingIndicatorPayload,
    TypingPayload,
    UnreadUpdatePayload,
    UserLeftPayload,
    build_error_message,
    build_server_message,
    parse_client_message,
)

router = APIRouter()
logger = logging.getLogger(__name__)

async def _authenticate(token: str, db: AsyncSession) -> User | None:
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            return None
        user_id = int(payload["sub"])
    except Exception:
        return None

    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()

async def _is_member(user_id: int, room_id: int, db: AsyncSession) -> RoomMember | None:
    result = await db.execute(
        select(RoomMember).where(
            RoomMember.room_id == room_id,
            RoomMember.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


# ---------------------------------------------------------------------------
# Event handlers
# ---------------------------------------------------------------------------

async def handle_join_room(
    user: User,
    payload: JoinRoomPayload,
    db: AsyncSession,
    presence: PresenceService,
    websocket: WebSocket,
) -> None:
    member = await _is_member(user.id, payload.room_id, db)
    if not member:
        await websocket.send_text(
            build_error_message("NOT_MEMBER", f"You are not a member of room {payload.room_id}"),
        )
        return

    manager.connect(user.id, payload.room_id, websocket)
    await presence.user_connected(
        user_id=user.id,
        room_id=payload.room_id,
        username=user.username,
        unread_count=member.unread_count,
    )
    await presence.send_online_members(payload.room_id, user.id)
    logger.info("JOIN_ROOM: user=%s room=%s | online=%s",
                user.id, payload.room_id,
                [m["user_id"] for m in manager.get_online_members(payload.room_id)])


async def handle_leave_room(
    user: User,
    payload: LeaveRoomPayload,
    db: AsyncSession,
    presence: PresenceService,
) -> None:
    await manager.broadcast(
        payload.room_id,
        build_server_message(
            ServerEvent.USER_LEFT,
            UserLeftPayload(room_id=payload.room_id, user_id=user.id, username=user.username),
        ),
        exclude_user=user.id,
    )
    manager.disconnect(user.id, payload.room_id)


async def handle_send_message(
    user: User,
    payload: SendMessagePayload,
    db: AsyncSession,
) -> None:
    member = await _is_member(user.id, payload.room_id, db)
    if not member:
        await manager.send_personal(
            user.id,
            build_error_message("NOT_MEMBER", "Cannot send to a room you're not in"),
        )
        return

    message = Message(
        room_id=payload.room_id,
        user_id=user.id,
        content=payload.content,
        message_type=payload.content_type,
        created_at=datetime.utcnow(),
    )
    db.add(message)
    await db.flush()

    new_msg_payload = NewMessagePayload(
        room_id=payload.room_id,
        message_id=message.id,
        sender_id=user.id,
        sender_username=user.username,
        content=payload.content,
        content_type=payload.content_type,
        created_at=message.created_at,
        file_url=message.file_url,
        file_name=message.file_name,
    )
    broadcast_text = build_server_message(ServerEvent.NEW_MESSAGE, new_msg_payload)

    online_ids = [m["user_id"] for m in manager.get_online_members(payload.room_id)]
    logger.info("SEND_MESSAGE: room=%s sender=%s online_members=%s", payload.room_id, user.id, online_ids)

    await manager.broadcast(payload.room_id, broadcast_text)

    await db.execute(
        update(RoomMember)
        .where(
            RoomMember.room_id == payload.room_id,
            RoomMember.user_id != user.id,
        )
        .values(unread_count=RoomMember.unread_count + 1)
    )

    if online_ids:
        await db.execute(
            update(RoomMember)
            .where(
                RoomMember.room_id == payload.room_id,
                RoomMember.user_id.in_(online_ids),
            )
            .values(unread_count=0, last_read_message_id=message.id)
        )

    await db.commit()


async def handle_typing(
    user: User,
    payload: TypingPayload,
    is_typing: bool,
) -> None:
    await manager.broadcast(
        payload.room_id,
        build_server_message(
            ServerEvent.TYPING_INDICATOR,
            TypingIndicatorPayload(
                room_id=payload.room_id,
                user_id=user.id,
                username=user.username,
                is_typing=is_typing,
            ),
        ),
        exclude_user=user.id,
    )


async def handle_sync_messages(
    user: User,
    payload: SyncMessagesPayload,
    db: AsyncSession,
) -> None:
    result = await db.execute(
        select(Message)
        .where(
            Message.room_id == payload.room_id,
            Message.id > payload.last_message_id,
        )
        .order_by(Message.id.asc())
        .limit(200)
    )
    messages = result.scalars().all()

    sender_ids = {m.user_id for m in messages}
    users_map: dict[int, User] = {}
    if sender_ids:
        users_result = await db.execute(select(User).where(User.id.in_(sender_ids)))
        users_map = {u.id: u for u in users_result.scalars()}

    msg_payloads = [
        NewMessagePayload(
            room_id=m.room_id,
            message_id=m.id,
            sender_id=m.user_id,
            sender_username=users_map[m.user_id].username,
            content=m.content,
            content_type=m.message_type,
            created_at=m.created_at,
            file_url=m.file_url,
            file_name=m.file_name,
        )
        for m in messages
    ]

    await manager.send_to_user_in_room(
        user.id,
        payload.room_id,
        build_server_message(
            ServerEvent.SYNC_RESPONSE,
            SyncResponsePayload(room_id=payload.room_id, messages=msg_payloads),
        ),
    )


async def handle_mark_read(
    user: User,
    payload: MarkReadPayload,
    db: AsyncSession,
) -> None:
    await db.execute(
        update(RoomMember)
        .where(
            RoomMember.room_id == payload.room_id,
            RoomMember.user_id == user.id,
        )
        .values(unread_count=0, last_read_message_id=payload.message_id)
    )
    await db.commit()

    await manager.send_to_user_in_room(
        user.id,
        payload.room_id,
        build_server_message(
            ServerEvent.UNREAD_UPDATE,
            UnreadUpdatePayload(
                room_id=payload.room_id,
                unread_count=0,
                last_read_message_id=payload.message_id,
            ),
        ),
    )

@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str,
    db: AsyncSession = Depends(get_db),
) -> None:
    user = await _authenticate(token, db)
    if not user:
        await websocket.close(code=4001, reason="Unauthorized")
        return

    await websocket.accept()
    await websocket.send_text(json.dumps({
        "type": "connected",
        "payload": {"user_id": user.id, "username": user.username}
    }))
    logger.info("WS CONNECTED: user=%s username=%s", user.id, user.username)

    presence = PresenceService(db)

    try:
        while True:
            raw = await websocket.receive_text()

            try:
                event_type, payload = parse_client_message(raw)
            except ValueError as exc:
                await websocket.send_text(
                    build_error_message("PARSE_ERROR", str(exc))
                )
                continue

            match event_type:
                case ClientEvent.JOIN_ROOM:
                    await handle_join_room(user, payload, db, presence, websocket)

                case ClientEvent.LEAVE_ROOM:
                    await handle_leave_room(user, payload, db, presence) 

                case ClientEvent.SEND_MESSAGE:
                    await handle_send_message(user, payload, db) 

                case ClientEvent.TYPING:
                    await handle_typing(user, payload, is_typing=True)

                case ClientEvent.STOP_TYPING:
                    await handle_typing(user, payload, is_typing=False)

                case ClientEvent.SYNC_MESSAGES:
                    await handle_sync_messages(user, payload, db)

                case ClientEvent.MARK_READ:
                    await handle_mark_read(user, payload, db) 

                case ClientEvent.PING:
                    await websocket.send_text(
                        build_server_message(ServerEvent.PONG, PongPayload())
                    )

    except WebSocketDisconnect:
        logger.info("WS DISCONNECTED: user=%s", user.id)
    except Exception as exc:
        logger.exception("Unexpected WS error for user=%s: %s", user.id, exc)
    finally:
        manager.disconnect_all(user.id)
        await presence.user_disconnected(user.id, user.username)