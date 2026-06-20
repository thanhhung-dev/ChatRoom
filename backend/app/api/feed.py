from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.feed import (
    FeedCommentResponse,
    FeedPostResponse,
    FeedPostUpdateRequest,
    FeedReactionRequest,
)
from app.services import feed_service
from app.utils.file_storage import save_file

router = APIRouter(prefix="/api/v1/feed", tags=["feed"])


@router.get("/posts", response_model=list[FeedPostResponse])
async def list_posts(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[FeedPostResponse]:
    return await feed_service.list_feed(db, current_user.id)


@router.post("/posts", response_model=FeedPostResponse, status_code=status.HTTP_201_CREATED)
async def create_post(
    content: str | None = Form(None),
    file: UploadFile | None = File(None),
    files: list[UploadFile] | None = File(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> FeedPostResponse:
    media_url = None
    media_name = None
    media_items: list[tuple[str, str | None]] = []
    if file is not None and file.filename:
        media_url, media_name = save_file(file, current_user.id)
        media_items.append((media_url, media_name))
    for item in files or []:
        if item is not None and item.filename:
            item_url, item_name = save_file(item, current_user.id)
            media_items.append((item_url, item_name))
    return await feed_service.create_post(
        db,
        user_id=current_user.id,
        content=content,
        media_url=media_url,
        media_name=media_name,
        media_items=media_items,
    )


@router.patch("/posts/{post_id}", response_model=FeedPostResponse)
async def update_post(
    post_id: int,
    data: FeedPostUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> FeedPostResponse:
    return await feed_service.update_post(db, post_id, current_user.id, data.content)


@router.delete("/posts/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_post(
    post_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    await feed_service.delete_post(db, post_id, current_user.id)


@router.post("/posts/{post_id}/reactions", response_model=FeedPostResponse)
async def react_to_post(
    post_id: int,
    data: FeedReactionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> FeedPostResponse:
    return await feed_service.set_reaction(db, post_id, current_user.id, data.reaction)


@router.get("/posts/{post_id}/comments", response_model=list[FeedCommentResponse])
async def list_comments(
    post_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[FeedCommentResponse]:
    return await feed_service.list_comments(db, post_id, current_user.id)


@router.post(
    "/posts/{post_id}/comments",
    response_model=FeedCommentResponse,
    status_code=status.HTTP_201_CREATED,
)
async def add_comment(
    post_id: int,
    content: str | None = Form(None),
    file: UploadFile | None = File(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> FeedCommentResponse:
    media_url = None
    media_name = None
    if file is not None and file.filename:
        media_url, media_name = save_file(file, current_user.id)
    return await feed_service.add_comment(
        db,
        post_id,
        current_user.id,
        content,
        media_url=media_url,
        media_name=media_name,
    )
