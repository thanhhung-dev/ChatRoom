from __future__ import annotations

import logging

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.ws.manager import manager
from app.ws.protocol import (
    OnlineMembersPayload,
    ServerEvent,
    UserJoinedPayload,
    UserLeftPayload,
    build_server_message,
)

logger = logging.getLogger(__name__)


class PresenceService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def user_connected(
        self,
        user_id: int,
        room_id: int,
        username: str,
        unread_count: int = 0,
    ) -> None:
        """
        Called after WebSocket is accepted and user joins a room.
        Broadcasts user_joined to all other members.
        """
        msg = build_server_message(
            ServerEvent.USER_JOINED,
            UserJoinedPayload(
                room_id=room_id,
                user_id=user_id,
                username=username,
                unread_count=unread_count,
            ),
        )
        await manager.broadcast(room_id, msg, exclude_user=user_id)
        logger.info("presence: user_connected user=%s room=%s", user_id, room_id)

    async def user_disconnected(
        self,
        user_id: int,
        username: str,
    ) -> None:
        """
        Called when a WebSocket fully disconnects.
        Broadcasts user_left to every room the user was in, then cleans up.
        """
        room_ids = manager.get_user_rooms(user_id)

        for room_id in room_ids:
            msg = build_server_message(
                ServerEvent.USER_LEFT,
                UserLeftPayload(room_id=room_id, user_id=user_id, username=username),
            )
            await manager.broadcast(room_id, msg, exclude_user=user_id)

        manager.disconnect_all(user_id)
        logger.info("presence: user_disconnected user=%s rooms=%s", user_id, room_ids)

   

    def get_online_users(self, room_id: int) -> list[int]:
        """Return user_ids currently connected to room_id."""
        return [m["user_id"] for m in manager.get_online_members(room_id)]

    async def send_online_members(self, room_id: int, to_user_id: int) -> None:
        """
        Send the current online member list of a room to a single user.
        Called right after join_room so the joiner knows who's online.
        """
        members = manager.get_online_members(room_id)
        msg = build_server_message(
            ServerEvent.ONLINE_MEMBERS,
            OnlineMembersPayload(room_id=room_id, members=members),
        )
        await manager.send_to_user_in_room(to_user_id, room_id, msg)