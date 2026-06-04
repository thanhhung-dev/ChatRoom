from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    verify_password,
)
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    TokenResponse,
)
from app.services import user_service


async def register(db: AsyncSession, data: RegisterRequest) -> TokenResponse:
    if await user_service.get_by_username(db, data.username):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username already registered",
        )
    if await user_service.get_by_email(db, data.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )
    user = await user_service.create_user(
        db,
        username=data.username,
        email=data.email,
        password=data.password,
        display_name=data.username,
    )
    return _build_tokens(str(user.id))


async def login(db: AsyncSession, data: LoginRequest) -> TokenResponse:
    user = await user_service.get_by_username(db, data.username)
    if user is None or not verify_password(data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
        )
    await user_service.set_online_status(db, user.id, True)
    return _build_tokens(str(user.id))


async def refresh_token(db: AsyncSession, token: str) -> TokenResponse:
    try:
        payload = decode_token(token)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        )
    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token is not a refresh token",
        )
    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
        )
    user = await user_service.get_by_id(db, int(user_id))
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )
    return _build_tokens(str(user.id))


async def logout(db: AsyncSession, token: str) -> None:
    try:
        payload = decode_token(token)
    except Exception:
        return
    user_id = payload.get("sub")
    if user_id:
        await user_service.set_online_status(db, int(user_id), False)


def _build_tokens(user_id: str) -> TokenResponse:
    token_data = {"sub": user_id}
    return TokenResponse(
        access_token=create_access_token(token_data),
        refresh_token=create_refresh_token(token_data),
    )
