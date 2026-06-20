from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.room import (
    CreateRoomRequest,
    JoinRoomRequest,
    RoomDetailResponse,
    RoomMemberResponse,
    RoomResponse,
    UpdateRoomRequest,
)
from app.services import room_service

router = APIRouter(prefix="/api/v1/rooms", tags=["rooms"])


@router.post(
    "",
    response_model=RoomResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Tạo phòng",
    description="Tạo phòng chat mới; người tạo trở thành admin và một mã mời được sinh tự động.",
)
async def create_room(
    data: CreateRoomRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> RoomResponse:
    return await room_service.create_room(db, current_user.id, data)


@router.get(
    "",
    summary="Danh sách phòng của tôi",
    description="Trả về danh sách phòng người dùng tham gia, có phân trang (`page`, `per_page`) "
    "và tìm kiếm theo tên (`search`).",
)
async def get_my_rooms(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    search: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    return await room_service.get_user_rooms(
        db, current_user.id, page, per_page, search
    )


@router.get(
    "/{room_id}",
    response_model=RoomDetailResponse,
    summary="Chi tiết phòng",
    description="Trả về chi tiết phòng kèm danh sách thành viên.",
)
async def get_room(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> RoomDetailResponse:
    room = await room_service.get_room(db, room_id)
    return room


@router.patch(
    "/{room_id}",
    response_model=RoomResponse,
    summary="Cập nhật phòng",
    description="Cập nhật tên/mô tả phòng. Chỉ admin của phòng được phép.",
)
async def update_room(
    room_id: int,
    data: UpdateRoomRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> RoomResponse:
    return await room_service.update_room(db, room_id, current_user.id, data)


@router.delete(
    "/{room_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Xoá phòng",
    description="Xoá phòng và toàn bộ dữ liệu liên quan. Chỉ chủ phòng được phép.",
)
async def delete_room(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    await room_service.delete_room(db, room_id, current_user.id)


@router.post(
    "/join",
    response_model=RoomResponse,
    summary="Tham gia phòng bằng mã mời",
    description="Tham gia phòng bằng `invite_code`. Lỗi nếu mã không hợp lệ hoặc đã là thành viên.",
)
async def join_room(
    data: JoinRoomRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> RoomResponse:
    return await room_service.join_room(db, current_user.id, data.invite_code)


@router.post(
    "/{room_id}/leave",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Rời phòng",
    description="Người dùng hiện tại rời khỏi phòng.",
)
async def leave_room(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    await room_service.leave_room(db, room_id, current_user.id)


@router.post(
    "/{room_id}/invite-code",
    summary="Tạo lại mã mời",
    description="Sinh mã mời mới cho phòng và trả về `{\"invite_code\": ...}`. "
    "Mã cũ sẽ không còn dùng được.",
)
async def regenerate_invite_code(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    code = await room_service.generate_invite_code(db, room_id)
    return {"invite_code": code}


@router.delete(
    "/{room_id}/members/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Xoá thành viên",
    description="Kick một thành viên khỏi phòng. Chỉ admin được phép.",
)
async def kick_member(
    room_id: int,
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    await room_service.kick_member(db, room_id, current_user.id, user_id)
