"""
WebSocket protocol definitions.
All client ↔ server message types, Pydantic models, serialize/deserialize.
"""
from __future__ import annotations

import json
from datetime import datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, field_validator


class ClientEvent(str, Enum):
    JOIN_ROOM     = "join_room"
    LEAVE_ROOM    = "leave_room"
    SEND_MESSAGE  = "send_message"
    TYPING        = "typing"
    STOP_TYPING   = "stop_typing"
    SYNC_MESSAGES = "sync_messages"
    MARK_READ     = "mark_read"
    PING          = "ping"


class ServerEvent(str, Enum):
    CONNECTED         = "connected"
    USER_JOINED       = "user_joined"
    USER_LEFT         = "user_left"
    NEW_MESSAGE       = "new_message"
    TYPING_INDICATOR  = "typing_indicator"
    UNREAD_UPDATE     = "unread_update"
    SYNC_RESPONSE     = "sync_response"
    PONG              = "pong"
    ERROR             = "error"
    ONLINE_MEMBERS    = "online_members"



class WSMessage(BaseModel):
    type: str
    payload: dict[str, Any] = {}



class JoinRoomPayload(BaseModel):
    room_id: int


class LeaveRoomPayload(BaseModel):
    room_id: int


class SendMessagePayload(BaseModel):
    room_id: int
    content: str
    content_type: str = "text"   

    @field_validator("content")
    @classmethod
    def content_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("content must not be empty")
        return v


class TypingPayload(BaseModel):
    room_id: int


class SyncMessagesPayload(BaseModel):
    room_id: int
    last_message_id: int         


class MarkReadPayload(BaseModel):
    room_id: int
    message_id: int              


class PingPayload(BaseModel):
    pass



class UserJoinedPayload(BaseModel):
    room_id: int
    user_id: int
    username: str
    unread_count: int = 0


class ConnectedPayload(BaseModel):
    user_id: int
    username: str


class UserLeftPayload(BaseModel):
    room_id: int
    user_id: int
    username: str


class NewMessagePayload(BaseModel):
    room_id: int
    message_id: int
    sender_id: int
    sender_username: str
    content: str | None = None
    content_type: str
    created_at: datetime
    file_url: str | None = None
    file_name: str | None = None


class TypingIndicatorPayload(BaseModel):
    room_id: int
    user_id: int
    username: str
    is_typing: bool


class UnreadUpdatePayload(BaseModel):
    room_id: int
    unread_count: int
    last_read_message_id: int


class SyncResponsePayload(BaseModel):
    room_id: int
    messages: list[NewMessagePayload]


class PongPayload(BaseModel):
    pass


class ErrorPayload(BaseModel):
    code: str
    detail: str


class OnlineMembersPayload(BaseModel):
    room_id: int
    members: list[dict[str, Any]]   # [{user_id, username, avatar_url?}]



_CLIENT_PAYLOAD_MAP: dict[ClientEvent, type[BaseModel]] = {
    ClientEvent.JOIN_ROOM:     JoinRoomPayload,
    ClientEvent.LEAVE_ROOM:    LeaveRoomPayload,
    ClientEvent.SEND_MESSAGE:  SendMessagePayload,
    ClientEvent.TYPING:        TypingPayload,
    ClientEvent.STOP_TYPING:   TypingPayload,
    ClientEvent.SYNC_MESSAGES: SyncMessagesPayload,
    ClientEvent.MARK_READ:     MarkReadPayload,
    ClientEvent.PING:          PingPayload,
}


def parse_client_message(raw: str) -> tuple[ClientEvent, BaseModel]:
    """
    Parse a raw JSON string from the client.
    Returns (event_type, validated_payload).
    Raises ValueError on unknown event or validation error.
    """
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON: {exc}") from exc

    event_type_str = data.get("type")
    if not event_type_str:
        raise ValueError("Missing 'type' field")

    try:
        event_type = ClientEvent(event_type_str)
    except ValueError:
        raise ValueError(f"Unknown client event: {event_type_str!r}")

    payload_cls = _CLIENT_PAYLOAD_MAP[event_type]
    payload = payload_cls.model_validate(data.get("payload", {}))
    return event_type, payload


def build_server_message(event: ServerEvent, payload: BaseModel) -> str:
    """Serialize a server event to JSON string ready to send over WebSocket."""
    return json.dumps(
        {
            "type": event.value,
            "payload": payload.model_dump(mode="json"),
        }
    )


def build_error_message(code: str, detail: str) -> str:
    return build_server_message(ServerEvent.ERROR, ErrorPayload(code=code, detail=detail))
