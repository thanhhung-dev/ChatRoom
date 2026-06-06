from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.message import MessageResponse
from app.schemas.user import UserPublicResponse


class CreateRoomRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: str = Field("", max_length=500)


class UpdateRoomRequest(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=100)
    description: str | None = Field(None, max_length=500)
    avatar_url: str | None = Field(None, max_length=500)


class RoomMemberResponse(BaseModel):
    id: int
    user: UserPublicResponse
    role: str
    joined_at: datetime

    model_config = {"from_attributes": True}


class RoomResponse(BaseModel):
    id: int
    name: str
    description: str | None
    avatar_url: str | None = None
    invite_code: str
    created_by: int
    member_count: int = 0
    unread_count: int = 0
    last_message: MessageResponse | None = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class RoomDetailResponse(RoomResponse):
    members: list[RoomMemberResponse] = []


class JoinRoomRequest(BaseModel):
    invite_code: str
