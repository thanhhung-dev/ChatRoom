import io

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_messages_empty(client: AsyncClient, auth_headers: dict, room_id: int):
    resp = await client.get(
        f"/api/v1/rooms/{room_id}/messages",
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["items"] == []
    assert data["total"] == 0


@pytest.mark.asyncio
async def test_upload_file(client: AsyncClient, auth_headers: dict, room_id: int):
    file_content = b"hello world"
    resp = await client.post(
        f"/api/v1/rooms/{room_id}/messages/file",
        headers=auth_headers,
        files={"file": ("test.txt", io.BytesIO(file_content), "text/plain")},
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["message_type"] == "file"
    assert data["file_name"] == "test.txt"
    assert data["file_url"] is not None


@pytest.mark.asyncio
async def test_upload_file_too_large(client: AsyncClient, auth_headers: dict, room_id: int):
    large_content = b"x" * (11 * 1024 * 1024)  # 11MB
    resp = await client.post(
        f"/api/v1/rooms/{room_id}/messages/file",
        headers=auth_headers,
        files={"file": ("large.txt", io.BytesIO(large_content), "text/plain")},
    )
    assert resp.status_code == 413


@pytest.mark.asyncio
async def test_get_messages_with_pagination(client: AsyncClient, auth_headers: dict, room_id: int):
    # Upload some files to create messages
    for i in range(3):
        await client.post(
            f"/api/v1/rooms/{room_id}/messages/file",
            headers=auth_headers,
            files={"file": (f"file{i}.txt", io.BytesIO(b"content"), "text/plain")},
        )

    resp = await client.get(
        f"/api/v1/rooms/{room_id}/messages",
        headers=auth_headers,
        params={"page": 1, "per_page": 2},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) == 2
    assert data["total"] == 3
    assert data["page"] == 1
    assert data["per_page"] == 2


@pytest.mark.asyncio
async def test_get_messages_with_before_id(client: AsyncClient, auth_headers: dict, room_id: int):
    # Create messages
    ids = []
    for i in range(3):
        resp = await client.post(
            f"/api/v1/rooms/{room_id}/messages/file",
            headers=auth_headers,
            files={"file": (f"f{i}.txt", io.BytesIO(b"content"), "text/plain")},
        )
        ids.append(resp.json()["id"])

    resp = await client.get(
        f"/api/v1/rooms/{room_id}/messages",
        headers=auth_headers,
        params={"before_id": ids[2]},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert all(m["id"] < ids[2] for m in data["items"])


@pytest.mark.asyncio
async def test_search_messages(client: AsyncClient, auth_headers: dict, room_id: int):
    # Create a file message first
    await client.post(
        f"/api/v1/rooms/{room_id}/messages/file",
        headers=auth_headers,
        files={"file": ("searchable.txt", io.BytesIO(b"content"), "text/plain")},
    )

    resp = await client.get(
        f"/api/v1/rooms/{room_id}/messages",
        headers=auth_headers,
        params={"search": "searchable"},
    )
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_upload_invalid_file_type(client: AsyncClient, auth_headers: dict, room_id: int):
    resp = await client.post(
        f"/api/v1/rooms/{room_id}/messages/file",
        headers=auth_headers,
        files={"file": ("malware.exe", io.BytesIO(b"bad"), "application/octet-stream")},
    )
    assert resp.status_code == 400
