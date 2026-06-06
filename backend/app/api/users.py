from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.user import UpdateProfileRequest, UserPublicResponse, UserResponse
from app.services import user_service

router = APIRouter(prefix="/api/v1/users", tags=["users"])


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Lấy hồ sơ của tôi",
    description="Trả về thông tin đầy đủ của người dùng đang đăng nhập (bao gồm email).",
)
async def get_me(
    current_user: User = Depends(get_current_user),
) -> User:
    return current_user


@router.patch(
    "/me",
    response_model=UserResponse,
    summary="Cập nhật hồ sơ",
    description="Cập nhật display_name và/hoặc avatar_url của người dùng hiện tại.",
)
async def update_me(
    data: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> User:
    return await user_service.update_profile(db, current_user.id, data)


@router.put(
    "/me/password",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Đổi mật khẩu",
    description="Đổi mật khẩu sau khi xác minh mật khẩu cũ. Lỗi 400 nếu mật khẩu cũ sai.",
)
async def change_password(
    old_password: str,
    new_password: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    success = await user_service.update_password(
        db, current_user.id, old_password, new_password
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect old password",
        )


@router.get(
    "/{user_id}",
    response_model=UserPublicResponse,
    summary="Lấy hồ sơ công khai",
    description="Trả về thông tin công khai (không có email) của một người dùng. "
    "Lỗi 404 nếu không tìm thấy.",
)
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
) -> User:
    user = await user_service.get_by_id(db, user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return user
