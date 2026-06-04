from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.user import UpdateProfileRequest, UserPublicResponse, UserResponse
from app.services import user_service

router = APIRouter(prefix="/api/v1/users", tags=["users"])


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: User = Depends(get_current_user),
) -> User:
    return current_user


@router.patch("/me", response_model=UserResponse)
async def update_me(
    data: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> User:
    return await user_service.update_profile(db, current_user.id, data)


@router.put("/me/password", status_code=status.HTTP_204_NO_CONTENT)
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


@router.get("/{user_id}", response_model=UserPublicResponse)
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
