from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db
from app.schemas.auth import (
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
)
from app.services import auth_service

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(
    data: RegisterRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    return await auth_service.register(db, data)


@router.post("/login", response_model=TokenResponse)
async def login(
    data: LoginRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    return await auth_service.login(db, data)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    data: RefreshRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    return await auth_service.refresh_token(db, data.refresh_token)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    data: RefreshRequest,
    db: AsyncSession = Depends(get_db),
) -> None:
    await auth_service.logout(db, data.refresh_token)
