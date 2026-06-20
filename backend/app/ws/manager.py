from __future__ import annotations

import asyncio
import logging
from typing import Any

from fastapi import WebSocket

logger = logging.getLogger(__name__)


class ConnectionManager:
    def __init__(self) -> None:
        # room_id -> {user_id -> WebSocket}
        self.rooms: dict[int, dict[int, WebSocket]] = {}
        # user_id -> set of room_ids
        self.user_rooms: dict[int, set[int]] = {}

    def connect(self, user_id: int, room_id: int, websocket: WebSocket) -> None:
        """Register an already-accepted WebSocket for (user_id, room_id)."""
        self.rooms.setdefault(room_id, {})[user_id] = websocket
        self.user_rooms.setdefault(user_id, set()).add(room_id)

        logger.info("WS connected: user=%s room=%s", user_id, room_id)

    def disconnect(self, user_id: int, room_id: int) -> None:
        """Remove a single (user, room) connection."""
        room = self.rooms.get(room_id)
        if room and user_id in room:
            del room[user_id]
            if not room:                          
                del self.rooms[room_id]

        rooms_of_user = self.user_rooms.get(user_id)
        if rooms_of_user:
            rooms_of_user.discard(room_id)
            if not rooms_of_user:
                del self.user_rooms[user_id]

        logger.info("WS disconnected: user=%s room=%s", user_id, room_id)

    def disconnect_all(self, user_id: int) -> list[int]:
        """
        Remove all connections for user_id (e.g. on total disconnect).
        Returns the list of room_ids the user was in.
        """
        room_ids = list(self.user_rooms.pop(user_id, set()))
        for room_id in room_ids:
            room = self.rooms.get(room_id)
            if room:
                room.pop(user_id, None)
                if not room:
                    del self.rooms[room_id]

        logger.info("WS disconnect_all: user=%s was in rooms=%s", user_id, room_ids)
        return room_ids

  
    async def broadcast(
        self,
        room_id: int,
        message: str,
        exclude_user: int | None = None,
    ) -> None:
        """Send a message to every connected member of a room."""
        room = self.rooms.get(room_id, {})
        dead: list[int] = []

        for uid, ws in room.items():
            if uid == exclude_user:
                continue
            try:
                await ws.send_text(message)
            except Exception:
                logger.warning("Failed to send to user=%s in room=%s, queuing cleanup", uid, room_id)
                dead.append(uid)

        for uid in dead:
            self.disconnect(uid, room_id)

    async def send_personal(self, user_id: int, message: str) -> None:
        """
        Send a message to all rooms this user is currently in.
        Useful for presence updates that target a specific user.
        """
        room_ids = list(self.user_rooms.get(user_id, set()))
        tasks = []
        for room_id in room_ids:
            ws = self.rooms.get(room_id, {}).get(user_id)
            if ws:
                tasks.append(ws.send_text(message))
        if tasks:
            results = await asyncio.gather(*tasks, return_exceptions=True)
            for room_id, result in zip(room_ids, results):
                if isinstance(result, Exception):
                    logger.warning("send_personal failed user=%s room=%s", user_id, room_id)
                    self.disconnect(user_id, room_id)

    async def send_to_user_in_room(
        self, user_id: int, room_id: int, message: str
    ) -> bool:
        """Send to a specific user in a specific room. Returns False if not connected."""
        ws = self.rooms.get(room_id, {}).get(user_id)
        if not ws:
            return False
        try:
            await ws.send_text(message)
            return True
        except Exception:
            self.disconnect(user_id, room_id)
            return False

    def get_online_members(self, room_id: int) -> list[dict[str, Any]]:
        """Return list of {user_id} for online members in a room."""
        room = self.rooms.get(room_id, {})
        return [{"user_id": uid} for uid in room]

    def is_user_online(self, user_id: int) -> bool:
        return user_id in self.user_rooms and bool(self.user_rooms[user_id])

    def is_user_in_room(self, user_id: int, room_id: int) -> bool:
        return user_id in self.rooms.get(room_id, {})

    def get_user_rooms(self, user_id: int) -> set[int]:
        return set(self.user_rooms.get(user_id, set()))


# Singleton — import this everywhere
manager = ConnectionManager()