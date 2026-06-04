from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password, verify_password
from app.models.user import User
from app.schemas.user import UpdateProfileRequest


async def create_user(
    db: AsyncSession,
    *,
    username: str,
    email: str,
    password: str,
    display_name: str,
) -> User:
    user = User(
        username=username,
        email=email,
        password_hash=hash_password(password),
        display_name=display_name,
        avatar_url="",
        is_online=False,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def get_by_username(db: AsyncSession, username: str) -> User | None:
    result = await db.execute(select(User).where(User.username == username))
    return result.scalar_one_or_none()


async def get_by_email(db: AsyncSession, email: str) -> User | None:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def get_by_id(db: AsyncSession, user_id: int) -> User | None:
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


async def update_profile(
    db: AsyncSession, user_id: int, data: UpdateProfileRequest
) -> User:
    user = await get_by_id(db, user_id)
    if user is None:
        raise ValueError("User not found")
    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)
    user.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(user)
    return user


async def update_password(
    db: AsyncSession, user_id: int, old_pw: str, new_pw: str
) -> bool:
    user = await get_by_id(db, user_id)
    if user is None:
        return False
    if not verify_password(old_pw, user.password_hash):
        return False
    user.password_hash = hash_password(new_pw)
    user.updated_at = datetime.utcnow()
    await db.commit()
    return True


async def set_online_status(
    db: AsyncSession, user_id: int, is_online: bool
) -> None:
    user = await get_by_id(db, user_id)
    if user is None:
        return
    user.is_online = is_online
    if not is_online:
        user.last_seen_at = datetime.utcnow()
    await db.commit()
