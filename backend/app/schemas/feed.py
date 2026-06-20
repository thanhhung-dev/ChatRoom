from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.schemas.user import UserPublicResponse


class FeedCommentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    post_id: int
    user: UserPublicResponse
    content: str | None
    media_url: str | None = None
    media_name: str | None = None
    media_type: str | None = None
    created_at: datetime


class FeedPostMediaResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    media_url: str
    media_name: str | None = None
    media_type: str | None = None
    sort_order: int


class FeedPostResponse(BaseModel):
    id: int
    user: UserPublicResponse
    content: str | None
    media_url: str | None
    media_name: str | None
    media_type: str | None
    reaction_count: int
    comment_count: int
    my_reaction: str | None
    created_at: datetime
    media_items: list[FeedPostMediaResponse] = []


class FeedReactionRequest(BaseModel):
    reaction: str


class FeedCommentRequest(BaseModel):
    content: str


class FeedPostUpdateRequest(BaseModel):
    content: str | None = None
