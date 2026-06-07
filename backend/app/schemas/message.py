from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.user import UserPublicResponse


class MessageResponse(BaseModel):
    id: int
    room_id: int
    user: UserPublicResponse
    content: str | None
    message_type: str
    file_url: str | None
    file_name: str | None
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class CreateMessageRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=5000)
    message_type: str = Field("text", max_length=20)


class MessageListResponse(BaseModel):
    items: list[MessageResponse]
    total: int
    page: int
    per_page: int
