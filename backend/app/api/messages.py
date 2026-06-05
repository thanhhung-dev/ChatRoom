from fastapi import APIRouter, Depends, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.message import MessageListResponse, MessageResponse
from app.services import message_service
from app.utils.file_storage import save_file

router = APIRouter(prefix="/api/v1/rooms/{room_id}/messages", tags=["messages"])


@router.get("", response_model=MessageListResponse)
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
