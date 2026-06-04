from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class UserResponse(BaseModel):
    id: int
    username: str
    email: EmailStr
    display_name: str
    avatar_url: str
    is_online: bool
    last_seen_at: datetime | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class UserPublicResponse(BaseModel):
    id: int
    username: str
    display_name: str
    avatar_url: str
    is_online: bool
    last_seen_at: datetime | None

    model_config = {"from_attributes": True}


class UpdateProfileRequest(BaseModel):
    display_name: str | None = Field(None, min_length=1, max_length=50)
    avatar_url: str | None = Field(None, max_length=255)
