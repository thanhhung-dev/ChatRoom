from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.room import RoomResponse
from app.schemas.user import UserPublicResponse


class SendFriendRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=30)


class FriendRequestResponse(BaseModel):
    id: int
    requester: UserPublicResponse
    receiver: UserPublicResponse
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class FriendshipResponse(BaseModel):
    id: int
    friend: UserPublicResponse
    room: RoomResponse | None = None
    created_at: datetime

    model_config = {"from_attributes": True}
