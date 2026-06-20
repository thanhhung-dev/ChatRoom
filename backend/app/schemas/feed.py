from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.schemas.user import UserPublicResponse


class FeedCommentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    post_id: int
    user: UserPublicResponse
    content: str
    created_at: datetime


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


class FeedReactionRequest(BaseModel):
    reaction: str


class FeedCommentRequest(BaseModel):
    content: str
