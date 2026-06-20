from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.friendship import Friendship
from app.models.user import User
from app.schemas.friend import FriendRequestResponse, FriendshipResponse, SendFriendRequest
from app.schemas.room import RoomResponse
from app.schemas.user import UserPublicResponse
from app.services import friend_service, room_service

router = APIRouter(prefix="/api/v1/friends", tags=["friends"])


@router.get("/search", response_model=list[UserPublicResponse])
async def search_users(
    q: str = Query(..., min_length=1),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[User]:
    return await friend_service.search_users(db, current_user.id, q)


@router.post("/requests", response_model=FriendRequestResponse, status_code=status.HTTP_201_CREATED)
async def send_friend_request(
    data: SendFriendRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await friend_service.send_request(db, current_user.id, data.username)


@router.get("/requests/incoming", response_model=list[FriendRequestResponse])
async def incoming_requests(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await friend_service.list_incoming(db, current_user.id)


@router.post("/requests/{request_id}/accept", response_model=FriendshipResponse)
async def accept_request(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> FriendshipResponse:
    friendship = await friend_service.respond_request(db, current_user.id, request_id, accept=True)
    assert friendship is not None
    return await _friendship_response(db, friendship, current_user.id)


@router.post("/requests/{request_id}/reject")
async def reject_request(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    await friend_service.respond_request(db, current_user.id, request_id, accept=False)
    return {"message": "rejected"}


@router.get("", response_model=list[FriendshipResponse])
async def list_friends(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[FriendshipResponse]:
    friendships = await friend_service.list_friends(db, current_user.id)
    return [await _friendship_response(db, item, current_user.id) for item in friendships]


@router.delete("/{friendship_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_friendship(
    friendship_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    await friend_service.delete_friendship(db, current_user.id, friendship_id)


async def _friendship_response(
    db: AsyncSession, friendship: Friendship, current_user_id: int
) -> FriendshipResponse:
    friend = (
        friendship.user_high
        if friendship.user_low_id == current_user_id
        else friendship.user_low
    )
    room_response: RoomResponse | None = None
    if friendship.room is not None:
        room_response = await room_service.build_room_response(db, friendship.room, current_user_id)
    return FriendshipResponse(
        id=friendship.id,
        friend=UserPublicResponse.model_validate(friend),
        room=room_response,
        created_at=friendship.created_at,
    )
