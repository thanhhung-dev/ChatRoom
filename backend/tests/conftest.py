import asyncio
import uuid

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from app.config import settings
from app.dependencies import get_db
from app.main import app
from app.models.base import Base

TEST_DATABASE_URL = settings.database_url.replace("chatroom_db", "chatroom_test_db")

engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestSessionLocal = async_sessionmaker(
    bind=engine, class_=AsyncSession, expire_on_commit=False
)


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


async def override_get_db() -> AsyncSession:
    async with TestSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


app.dependency_overrides[get_db] = override_get_db


@pytest_asyncio.fixture
async def client() -> AsyncClient:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest_asyncio.fixture
async def auth_headers(client: AsyncClient) -> dict:
    username = f"test_{uuid.uuid4().hex[:8]}"
    email = f"{username}@test.com"
    await client.post(
        "/api/v1/auth/register",
        json={"username": username, "email": email, "password": "12345678"},
    )
    resp = await client.post(
        "/api/v1/auth/login",
        json={"username": username, "password": "12345678"},
    )
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def room_id(client: AsyncClient, auth_headers: dict) -> int:
    resp = await client.post(
        "/api/v1/rooms",
        json={"name": "Test Room"},
        headers=auth_headers,
    )
    return resp.json()["id"]
