from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.message import CreateMessageRequest, MessageResponse
from app.schemas.room import (
    CreateRoomRequest,
    JoinRoomRequest,
    RoomDetailResponse,
    RoomMemberResponse,
    RoomResponse,
    UpdateRoomRequest,
)
from app.services import message_service, room_service
from app.utils.file_storage import save_file

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
    room = await room_service.create_room(db, current_user.id, data)
    return await room_service.build_room_response(db, room, current_user.id)


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


@router.post(
    "/{room_id}/avatar",
    response_model=RoomResponse,
    summary="Cập nhật ảnh nhóm",
)
async def upload_room_avatar(
    room_id: int,
    file: UploadFile,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> RoomResponse:
    await room_service.is_admin(db, room_id, current_user.id)
    file_url, _ = save_file(file, room_id)
    room = await room_service.update_room(
        db,
        room_id,
        current_user.id,
        UpdateRoomRequest(avatar_url=file_url),
    )
    return await room_service.build_room_response(db, room, current_user.id)


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
    response = await room_service.build_room_response(db, room, current_user.id)
    return RoomDetailResponse(**response.model_dump())


@router.post(
    "/{room_id}/messages",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Gửi tin nhắn văn bản",
    description="Tạo một tin nhắn text trong phòng. Yêu cầu là thành viên phòng.",
)
async def send_room_message(
    room_id: int,
    data: CreateMessageRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    return await message_service.create_message(
        db,
        room_id=room_id,
        user_id=current_user.id,
        content=data.content,
        message_type=data.message_type,
    )


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
    room = await room_service.update_room(db, room_id, current_user.id, data)
    return await room_service.build_room_response(db, room, current_user.id)


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
    room = await room_service.join_room(db, current_user.id, data.invite_code)
    return await room_service.build_room_response(db, room, current_user.id)


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
    if await room_service.is_direct_room(db, room_id):
        raise HTTPException(status_code=403, detail="Direct rooms do not have invites")
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
    if await room_service.is_direct_room(db, room_id):
        raise HTTPException(status_code=403, detail="Direct rooms are locked")
    await room_service.kick_member(db, room_id, current_user.id, user_id)


@router.post(
    "/{room_id}/members/{user_id}/make-admin",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Chuyển quyền quản trị viên",
)
async def make_admin(
    room_id: int,
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    if await room_service.is_direct_room(db, room_id):
        raise HTTPException(status_code=403, detail="Direct rooms are locked")
    await room_service.transfer_admin(db, room_id, current_user.id, user_id)
