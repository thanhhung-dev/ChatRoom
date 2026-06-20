# ChatRoom Backend

Backend cho ứng dụng chat thời gian thực, viết bằng **FastAPI** + **PostgreSQL** (async SQLAlchemy) với kênh **WebSocket** cho realtime.

## Tính năng

- Xác thực JWT (access + refresh token), đăng ký / đăng nhập / refresh / logout
- Quản lý hồ sơ người dùng, đổi mật khẩu
- Phòng chat: tạo / tham gia bằng mã mời / rời / quản lý thành viên
- Tin nhắn: lịch sử có phân trang & tìm kiếm, upload file
- WebSocket realtime: tin nhắn mới, typing indicator, trạng thái online, đồng bộ tin nhắn, đếm tin chưa đọc

## Yêu cầu

- Python 3.11+ (đang chạy trên 3.14)
- PostgreSQL 14+

## 1. Cài đặt

```bash
# Tạo & kích hoạt virtualenv
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate

# Cài dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt   # nếu muốn chạy test
```

## 2. Cấu hình môi trường

Sao chép file mẫu rồi chỉnh sửa:

```bash
cp .env.example .env
```

Các biến trong `.env`:

| Biến | Mô tả | Mặc định |
|------|-------|----------|
| `DATABASE_URL` | Chuỗi kết nối async PostgreSQL | `postgresql+asyncpg://user:pass@localhost:5432/chatroom_db` |
| `JWT_SECRET_KEY` | Khoá bí mật ký JWT (**đổi ở production**) | — |
| `JWT_ALGORITHM` | Thuật toán JWT | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Thời gian sống access token | `30` |
| `REFRESH_TOKEN_EXPIRE_DAYS` | Thời gian sống refresh token | `7` |
| `UPLOAD_DIR` | Thư mục lưu file upload | `./uploads` |
| `MAX_FILE_SIZE_MB` | Dung lượng file tối đa | `100` |

Tạo database (nếu chưa có):

```bash
createdb chatroom_db
createdb chatroom_test_db   # dùng cho test
```

## 3. Chạy migration

```bash
# Áp dụng tất cả migration mới nhất
alembic upgrade head

# Tạo migration mới sau khi đổi model
alembic revision --autogenerate -m "mô tả thay đổi"

# Quay lui 1 bước
alembic downgrade -1
```

## 4. Chạy server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Swagger UI: <http://localhost:8000/docs>
- ReDoc: <http://localhost:8000/redoc>
- Health check: <http://localhost:8000/health>

## 5. Chạy tests

```bash
pytest                       # toàn bộ
pytest tests/test_auth.py    # một file
pytest -q -k websocket       # lọc theo tên
```

> Test dùng database `chatroom_test_db` (tự suy ra từ `DATABASE_URL` bằng cách
> thay `chatroom_db` → `chatroom_test_db`). Schema được tạo/xoá tự động mỗi test.

## API endpoints

Tất cả REST endpoint (trừ auth) yêu cầu header:

```
Authorization: Bearer <access_token>
```

### Auth — `/api/v1/auth`
| Method | Path | Mô tả |
|--------|------|-------|
| POST | `/register` | Đăng ký, trả về access + refresh token |
| POST | `/login` | Đăng nhập |
| POST | `/refresh` | Làm mới token |
| POST | `/logout` | Đăng xuất (vô hiệu refresh token) |

### Users — `/api/v1/users`
| Method | Path | Mô tả |
|--------|------|-------|
| GET | `/me` | Hồ sơ của tôi |
| PATCH | `/me` | Cập nhật hồ sơ |
| PUT | `/me/password` | Đổi mật khẩu |
| GET | `/{user_id}` | Hồ sơ công khai của user khác |

### Rooms — `/api/v1/rooms`
| Method | Path | Mô tả |
|--------|------|-------|
| POST | `` | Tạo phòng |
| GET | `` | Danh sách phòng của tôi (phân trang, search) |
| GET | `/{room_id}` | Chi tiết phòng + thành viên |
| PATCH | `/{room_id}` | Cập nhật phòng (admin) |
| DELETE | `/{room_id}` | Xoá phòng (chủ phòng) |
| POST | `/join` | Tham gia bằng `invite_code` |
| POST | `/{room_id}/leave` | Rời phòng |
| POST | `/{room_id}/invite-code` | Tạo lại mã mời |
| DELETE | `/{room_id}/members/{user_id}` | Kick thành viên (admin) |

### Messages — `/api/v1/rooms/{room_id}/messages`
| Method | Path | Mô tả |
|--------|------|-------|
| GET | `` | Lịch sử tin nhắn (phân trang, `before_id`, `search`) |
| POST | `/file` | Upload file & tạo tin nhắn dạng file |

## WebSocket

Kết nối tới:

```
ws://localhost:8000/ws?token=<access_token>
```

Token không hợp lệ → server đóng kết nối với mã `4001`.

### Định dạng message

Mọi message (cả 2 chiều) là JSON dạng:

```json
{ "type": "<event>", "payload": { ... } }
```

### Client → Server

| `type` | `payload` | Ý nghĩa |
|--------|-----------|---------|
| `join_room` | `{ room_id }` | Tham gia phòng (nhận `online_members`) |
| `leave_room` | `{ room_id }` | Rời phòng |
| `send_message` | `{ room_id, content, content_type? }` | Gửi tin nhắn |
| `typing` | `{ room_id }` | Bắt đầu gõ |
| `stop_typing` | `{ room_id }` | Dừng gõ |
| `sync_messages` | `{ room_id, last_message_id }` | Lấy tin nhắn bỏ lỡ |
| `mark_read` | `{ room_id, message_id }` | Đánh dấu đã đọc |
| `ping` | `{}` | Giữ kết nối |

### Server → Client

| `type` | Ý nghĩa |
|--------|---------|
| `user_joined` | Có thành viên vào phòng |
| `user_left` | Có thành viên rời phòng |
| `new_message` | Tin nhắn mới |
| `typing_indicator` | Trạng thái đang gõ |
| `unread_update` | Cập nhật số tin chưa đọc |
| `sync_response` | Kết quả đồng bộ tin nhắn |
| `online_members` | Danh sách thành viên online |
| `pong` | Phản hồi `ping` |
| `error` | Lỗi (`{ code, detail }`) |

### Ví dụ

```jsonc
// → tham gia phòng 1
{ "type": "join_room", "payload": { "room_id": 1 } }

// → gửi tin nhắn
{ "type": "send_message", "payload": { "room_id": 1, "content": "Xin chào!" } }

// ← nhận tin nhắn mới
{ "type": "new_message", "payload": {
    "room_id": 1, "message_id": 42, "sender_id": 7,
    "sender_username": "alice", "content": "Xin chào!",
    "content_type": "text", "created_at": "2026-06-06T10:00:00Z"
} }
```

## Cấu trúc thư mục

```
backend/
├── app/
│   ├── api/          # REST routers (auth, users, rooms, messages)
│   ├── core/         # security (JWT, hashing)
│   ├── models/       # SQLAlchemy models
│   ├── schemas/      # Pydantic request/response
│   ├── services/     # business logic
│   ├── utils/        # file storage, helpers
│   ├── ws/           # WebSocket protocol, manager, handler
│   ├── config.py     # Pydantic settings
│   ├── dependencies.py
│   └── main.py       # app factory
├── alembic/          # migrations
├── tests/
├── uploads/          # file upload (gitignore ở production)
└── requirements*.txt
```
