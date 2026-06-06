"""
WebSocket integration tests (Phase 5, Task 5.6).

These use Starlette's synchronous TestClient because httpx (used by the async
REST fixtures) cannot open WebSocket connections. Schema is created/dropped with
a short-lived NullPool engine so the shared async `engine` from conftest stays
pristine for the TestClient event loop.
"""
import asyncio
import uuid

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import NullPool
from starlette.testclient import TestClient

from app.config import settings
from app.dependencies import get_db
from app.main import app
from app.models.base import Base

TEST_DATABASE_URL = settings.database_url.replace("chatroom_db", "chatroom_test_db")

# NullPool so connections are created fresh per-use and never reused across the
# separate event loop that Starlette's TestClient runs the app on.
_ws_engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool)
_WsSessionLocal = async_sessionmaker(
    bind=_ws_engine, class_=AsyncSession, expire_on_commit=False
)


async def _ws_get_db():
    async with _WsSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


@pytest.fixture(autouse=True)
def setup_db():
    """Shadow conftest's async autouse fixture with a sync one.

    Starlette's TestClient runs the app on its own event loop, which conflicts
    with conftest's async fixture sharing a pooled engine across loops. Here we
    create/drop the schema synchronously on throwaway loops via the NullPool
    engine, so no connection is ever reused across event loops.
    """
    async def _ddl(create: bool):
        async with _ws_engine.begin() as conn:
            if create:
                await conn.run_sync(Base.metadata.create_all)
            else:
                await conn.run_sync(Base.metadata.drop_all)

    asyncio.run(_ddl(create=True))
    yield
    asyncio.run(_ddl(create=False))


@pytest.fixture
def tc():
    previous = app.dependency_overrides.get(get_db)
    app.dependency_overrides[get_db] = _ws_get_db
    try:
        with TestClient(app) as c:
            yield c
    finally:
        if previous is not None:
            app.dependency_overrides[get_db] = previous


def _register_and_login(tc: TestClient) -> str:
    username = f"ws_{uuid.uuid4().hex[:8]}"
    tc.post(
        "/api/v1/auth/register",
        json={"username": username, "email": f"{username}@test.com", "password": "12345678"},
    )
    resp = tc.post(
        "/api/v1/auth/login",
        json={"username": username, "password": "12345678"},
    )
    return resp.json()["access_token"]


def _create_room(tc: TestClient, token: str) -> int:
    resp = tc.post(
        "/api/v1/rooms",
        json={"name": "WS Room"},
        headers={"Authorization": f"Bearer {token}"},
    )
    return resp.json()["id"]


def test_connect_invalid_token_rejected(tc: TestClient):
    from starlette.websockets import WebSocketDisconnect

    with pytest.raises(WebSocketDisconnect):
        with tc.websocket_connect("/ws?token=not-a-valid-token") as ws:
            ws.receive_text()


def test_join_room_returns_online_members(tc: TestClient):
    token = _register_and_login(tc)
    room_id = _create_room(tc, token)

    with tc.websocket_connect(f"/ws?token={token}") as ws:
        ws.send_json({"type": "join_room", "payload": {"room_id": room_id}})
        msg = ws.receive_json()
        assert msg["type"] == "online_members"
        assert msg["payload"]["room_id"] == room_id


def test_send_message_broadcasts_new_message(tc: TestClient):
    token = _register_and_login(tc)
    room_id = _create_room(tc, token)

    with tc.websocket_connect(f"/ws?token={token}") as ws:
        ws.send_json({"type": "join_room", "payload": {"room_id": room_id}})
        ws.receive_json()  # online_members

        ws.send_json(
            {"type": "send_message", "payload": {"room_id": room_id, "content": "hello"}}
        )
        msg = ws.receive_json()
        assert msg["type"] == "new_message"
        assert msg["payload"]["content"] == "hello"
        assert msg["payload"]["room_id"] == room_id
        assert msg["payload"]["message_id"] > 0


def test_send_message_to_unjoined_room_errors(tc: TestClient):
    token = _register_and_login(tc)

    with tc.websocket_connect(f"/ws?token={token}") as ws:
        ws.send_json(
            {"type": "send_message", "payload": {"room_id": 999999, "content": "hi"}}
        )
        msg = ws.receive_json()
        assert msg["type"] == "error"
        assert msg["payload"]["code"] == "NOT_MEMBER"


def test_ping_pong(tc: TestClient):
    token = _register_and_login(tc)

    with tc.websocket_connect(f"/ws?token={token}") as ws:
        ws.send_json({"type": "ping", "payload": {}})
        msg = ws.receive_json()
        assert msg["type"] == "pong"


def test_sync_messages_returns_missed(tc: TestClient):
    token = _register_and_login(tc)
    room_id = _create_room(tc, token)

    with tc.websocket_connect(f"/ws?token={token}") as ws:
        ws.send_json({"type": "join_room", "payload": {"room_id": room_id}})
        ws.receive_json()  # online_members

        ws.send_json(
            {"type": "send_message", "payload": {"room_id": room_id, "content": "first"}}
        )
        first = ws.receive_json()
        assert first["type"] == "new_message"

        ws.send_json(
            {"type": "sync_messages", "payload": {"room_id": room_id, "last_message_id": 0}}
        )
        resp = ws.receive_json()
        assert resp["type"] == "sync_response"
        assert len(resp["payload"]["messages"]) == 1
        assert resp["payload"]["messages"][0]["content"] == "first"


def test_parse_error_on_bad_json(tc: TestClient):
    token = _register_and_login(tc)

    with tc.websocket_connect(f"/ws?token={token}") as ws:
        ws.send_text("this is not json")
        msg = ws.receive_json()
        assert msg["type"] == "error"
        assert msg["payload"]["code"] == "PARSE_ERROR"
