from __future__ import annotations

import json
from pathlib import Path

from fastapi import HTTPException, status
from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.feed import FeedComment, FeedPost, FeedPostMedia, FeedReaction
from app.models.friendship import Friendship
from app.models.user import User
from app.schemas.feed import FeedCommentResponse, FeedPostMediaResponse, FeedPostResponse
from app.schemas.user import UserPublicResponse
from app.ws.manager import manager


def _media_type(file_name: str | None) -> str | None:
    if not file_name:
        return None
    ext = Path(file_name).suffix.lower()
    if ext in {".jpg", ".jpeg", ".png", ".gif", ".webp", ".heic", ".heif"}:
        return "image"
    if ext in {".mp4", ".mov", ".m4v", ".webm"}:
        return "video"
    return "file"


async def list_feed(db: AsyncSession, user_id: int) -> list[FeedPostResponse]:
    friend_ids = await _friend_ids(db, user_id)
    visible_ids = friend_ids | {user_id}
    result = await db.execute(
        select(FeedPost)
        .options(selectinload(FeedPost.user), selectinload(FeedPost.media_items))
        .where(FeedPost.user_id.in_(visible_ids))
        .order_by(FeedPost.created_at.desc(), FeedPost.id.desc())
        .limit(100)
    )
    posts = list(result.scalars())
    return [await build_post_response(db, post, user_id) for post in posts]


async def create_post(
    db: AsyncSession,
    user_id: int,
    content: str | None,
    media_url: str | None = None,
    media_name: str | None = None,
    media_items: list[tuple[str, str | None]] | None = None,
) -> FeedPostResponse:
    media_items = media_items or []
    if media_url and not media_items:
        media_items = [(media_url, media_name)]
    first_media_url = media_items[0][0] if media_items else media_url
    first_media_name = media_items[0][1] if media_items else media_name
    if not (content and content.strip()) and not first_media_url:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Post needs text or media",
        )

    post = FeedPost(
        user_id=user_id,
        content=content.strip() if content else None,
        media_url=first_media_url,
        media_name=first_media_name,
        media_type=_media_type(first_media_name or first_media_url),
    )
    db.add(post)
    await db.flush()
    for index, (url, name) in enumerate(media_items):
        db.add(
            FeedPostMedia(
                post_id=post.id,
                media_url=url,
                media_name=name,
                media_type=_media_type(name or url),
                sort_order=index,
            )
        )
    await db.flush()
    post_id = post.id
    await db.commit()
    post = await get_post(db, post_id)
    response = await build_post_response(db, post, user_id)
    await notify_friends_about_post(db, user_id, response)
    return response


async def update_post(
    db: AsyncSession,
    post_id: int,
    user_id: int,
    content: str | None,
) -> FeedPostResponse:
    post = await get_post(db, post_id)
    if post.user_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only owner can edit post")
    cleaned = content.strip() if content else None
    if not cleaned and not post.media_url:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Post needs text or media",
        )
    post.content = cleaned
    await db.commit()
    await db.refresh(post)
    return await build_post_response(db, post, user_id)


async def delete_post(db: AsyncSession, post_id: int, user_id: int) -> None:
    post = await get_post(db, post_id)
    if post.user_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only owner can delete post")
    await db.delete(post)
    await db.commit()


async def set_reaction(
    db: AsyncSession, post_id: int, user_id: int, reaction: str
) -> FeedPostResponse:
    post = await get_visible_post(db, post_id, user_id)
    reaction = reaction.strip()
    if not reaction:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Reaction is required")
    result = await db.execute(
        select(FeedReaction).where(
            FeedReaction.post_id == post_id, FeedReaction.user_id == user_id
        )
    )
    item = result.scalar_one_or_none()
    if item is None:
        db.add(FeedReaction(post_id=post_id, user_id=user_id, reaction=reaction))
    else:
        item.reaction = reaction
    await db.commit()
    await notify_post_owner_about_reaction(db, post, user_id, reaction)
    return await build_post_response(db, post, user_id)


async def add_comment(
    db: AsyncSession,
    post_id: int,
    user_id: int,
    content: str | None,
    media_url: str | None = None,
    media_name: str | None = None,
) -> FeedCommentResponse:
    await get_visible_post(db, post_id, user_id)
    cleaned = content.strip() if content else None
    if not cleaned and not media_url:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Comment is required")
    comment = FeedComment(
        post_id=post_id,
        user_id=user_id,
        content=cleaned,
        media_url=media_url,
        media_name=media_name,
        media_type=_media_type(media_name or media_url),
    )
    db.add(comment)
    await db.flush()
    comment_id = comment.id
    await db.commit()
    result = await db.execute(
        select(FeedComment)
        .options(selectinload(FeedComment.user))
        .where(FeedComment.id == comment_id)
    )
    saved = result.scalar_one()
    response = FeedCommentResponse(
        id=saved.id,
        post_id=saved.post_id,
        user=UserPublicResponse.model_validate(saved.user),
        content=saved.content,
        media_url=saved.media_url,
        media_name=saved.media_name,
        media_type=saved.media_type,
        created_at=saved.created_at,
    )
    post = await get_post(db, post_id)
    await notify_post_owner_about_comment(post, response)
    return response


async def list_comments(
    db: AsyncSession, post_id: int, user_id: int
) -> list[FeedCommentResponse]:
    await get_visible_post(db, post_id, user_id)
    result = await db.execute(
        select(FeedComment)
        .options(selectinload(FeedComment.user))
        .where(FeedComment.post_id == post_id)
        .order_by(FeedComment.created_at.asc(), FeedComment.id.asc())
    )
    return [
        FeedCommentResponse(
            id=item.id,
            post_id=item.post_id,
            user=UserPublicResponse.model_validate(item.user),
            content=item.content,
            media_url=item.media_url,
            media_name=item.media_name,
            media_type=item.media_type,
            created_at=item.created_at,
        )
        for item in result.scalars()
    ]


async def get_post(db: AsyncSession, post_id: int) -> FeedPost:
    result = await db.execute(
        select(FeedPost)
        .options(selectinload(FeedPost.user), selectinload(FeedPost.media_items))
        .where(FeedPost.id == post_id)
    )
    post = result.scalar_one_or_none()
    if post is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
    return post


async def get_visible_post(db: AsyncSession, post_id: int, user_id: int) -> FeedPost:
    post = await get_post(db, post_id)
    if post.user_id == user_id or await _are_friends(db, post.user_id, user_id):
        return post
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Post is not visible")


async def build_post_response(
    db: AsyncSession, post: FeedPost, current_user_id: int
) -> FeedPostResponse:
    reaction_count = (
        await db.execute(
            select(func.count(FeedReaction.id)).where(FeedReaction.post_id == post.id)
        )
    ).scalar() or 0
    comment_count = (
        await db.execute(select(func.count(FeedComment.id)).where(FeedComment.post_id == post.id))
    ).scalar() or 0
    my_reaction = (
        await db.execute(
            select(FeedReaction.reaction).where(
                FeedReaction.post_id == post.id,
                FeedReaction.user_id == current_user_id,
            )
        )
    ).scalar_one_or_none()
    media_items = [
        FeedPostMediaResponse(
            id=item.id,
            media_url=item.media_url,
            media_name=item.media_name,
            media_type=item.media_type,
            sort_order=item.sort_order,
        )
        for item in getattr(post, "media_items", [])
    ]
    if not media_items and post.media_url:
        media_items = [
            FeedPostMediaResponse(
                id=0,
                media_url=post.media_url,
                media_name=post.media_name,
                media_type=post.media_type,
                sort_order=0,
            )
        ]
    return FeedPostResponse(
        id=post.id,
        user=UserPublicResponse.model_validate(post.user),
        content=post.content,
        media_url=post.media_url,
        media_name=post.media_name,
        media_type=post.media_type,
        reaction_count=reaction_count,
        comment_count=comment_count,
        my_reaction=my_reaction,
        created_at=post.created_at,
        media_items=media_items,
    )


async def _friend_ids(db: AsyncSession, user_id: int) -> set[int]:
    result = await db.execute(
        select(Friendship).where(
            or_(Friendship.user_low_id == user_id, Friendship.user_high_id == user_id)
        )
    )
    ids: set[int] = set()
    for item in result.scalars():
        ids.add(item.user_high_id if item.user_low_id == user_id else item.user_low_id)
    return ids


async def _are_friends(db: AsyncSession, a: int, b: int) -> bool:
    low, high = (a, b) if a < b else (b, a)
    result = await db.execute(
        select(Friendship.id).where(
            and_(Friendship.user_low_id == low, Friendship.user_high_id == high)
        )
    )
    return result.scalar_one_or_none() is not None


async def notify_friends_about_post(
    db: AsyncSession, author_id: int, post: FeedPostResponse
) -> None:
    payload = {
        "type": "feed_post",
        "payload": {
            "post_id": post.id,
            "sender_id": author_id,
            "sender_username": post.user.username,
            "content": post.content,
            "media_type": post.media_type,
            "media_name": post.media_name,
        },
    }
    message = json.dumps(payload)
    for friend_id in await _friend_ids(db, author_id):
        await manager.send_personal(friend_id, message)


async def notify_post_owner_about_comment(
    post: FeedPost, comment: FeedCommentResponse
) -> None:
    if post.user_id == comment.user.id:
        return
    await manager.send_personal(
        post.user_id,
        json.dumps(
            {
                "type": "feed_comment",
                "payload": {
                    "comment_id": comment.id,
                    "post_id": post.id,
                    "sender_id": comment.user.id,
                    "sender_username": comment.user.username,
                    "sender_display_name": comment.user.display_name,
                    "content": comment.content,
                    "media_name": comment.media_name,
                },
            }
        ),
    )


async def notify_post_owner_about_reaction(
    db: AsyncSession, post: FeedPost, user_id: int, reaction: str
) -> None:
    if post.user_id == user_id:
        return
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        return
    await manager.send_personal(
        post.user_id,
        json.dumps(
            {
                "type": "feed_reaction",
                "payload": {
                    "post_id": post.id,
                    "sender_id": user.id,
                    "sender_username": user.username,
                    "sender_display_name": user.display_name,
                    "reaction": reaction,
                },
            }
        ),
    )
