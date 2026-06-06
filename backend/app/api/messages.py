from fastapi import APIRouter, Depends, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.message import MessageListResponse, MessageResponse
from app.services import message_service
from app.utils.file_storage import save_file

router = APIRouter(prefix="/api/v1/rooms/{room_id}/messages", tags=["messages"])


@router.get(
    "",
    response_model=MessageListResponse,
    summary="Lịch sử tin nhắn",
    description="Lấy tin nhắn trong phòng theo phân trang. Hỗ trợ `before_id` để cuộn "
    "ngược lịch sử và `search` để tìm theo nội dung. Yêu cầu là thành viên phòng.",
)
async def get_messages(
    room_id: int,
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=100),
    before_id: int | None = None,
    search: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageListResponse:
    return await message_service.get_messages(
        db, room_id, current_user.id, page, per_page, before_id, search
    )


@router.post(
    "/file",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Gửi tin nhắn file",
    description="Upload file (multipart/form-data) và tạo một tin nhắn dạng file trong phòng. "
    "File tối đa 10MB; loại file được giới hạn (ảnh/tài liệu).",
)
async def upload_file(
    room_id: int,
    file: UploadFile,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    file_url, file_name = save_file(file, room_id)
    message = await message_service.create_message(
        db,
        room_id=room_id,
        user_id=current_user.id,
        message_type="file",
        file_url=file_url,
        file_name=file_name,
    )
    return message
