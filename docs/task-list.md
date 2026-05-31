# Task List — Backend Implementation
## ChatRoom Backend — Python FastAPI

---

## Phase 1: Project Setup & Foundation

### Task 1.1: Khởi tạo project
- [ ] Tạo thư mục `backend/` theo cấu trúc trong `architecture.md`
- [ ] Tạo `requirements.txt` với các dependencies:
  ```
  fastapi>=0.110.0
  uvicorn[standard]>=0.27.0
  sqlalchemy[asyncio]>=2.0.25
  asyncpg>=0.29.0
  alembic>=1.13.0
  pydantic>=2.5.0
  pydantic-settings>=2.1.0
  python-jose[cryptography]>=3.3.0
  passlib[bcrypt]>=1.7.4
  python-multipart>=0.0.6
  aiofiles>=23.2.0
  ```
- [ ] Tạo `requirements-dev.txt`:
  ```
  pytest>=7.4.0
  pytest-asyncio>=0.23.0
  httpx>=0.26.0
  factory-boy>=3.3.0
  ```
- [ ] Tạo `.env.example`:
  ```
  DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/chatroom
  JWT_SECRET_KEY=your-secret-key-change-in-production
  JWT_ALGORITHM=HS256
  ACCESS_TOKEN_EXPIRE_MINUTES=15
  REFRESH_TOKEN_EXPIRE_DAYS=7
  UPLOAD_DIR=./uploads
  MAX_FILE_SIZE_MB=10
  ```
- [ ] Tạo `README.md` với hướng dẫn setup

### Task 1.2: Config & Settings
- [ ] Tạo `app/config.py` với Pydantic Settings
- [ ] Load biến môi trường từ `.env`
- [ ] Validate tất cả required settings khi startup

### Task 1.3: Database connection
- [ ] Tạo `app/models/base.py` — SQLAlchemy async engine, session factory
- [ ] Tạo Base model với mixins: `id`, `created_at`, `updated_at`
- [ ] Tạo `app/dependencies.py` — `get_db` dependency

### Task 1.4: Alembic setup
- [ ] Init alembic: `alembic init alembic`
- [ ] Configure `alembic.ini` và `alembic/env.py` cho async
- [ ] Test kết nối database

---

## Phase 2: User & Auth

### Task 2.1: User model
- [ ] Tạo `app/models/user.py` — SQLAlchemy model `User`
- [ ] Fields: id, username, email, password_hash, display_name, avatar_url, is_online, last_seen_at, created_at, updated_at
- [ ] Tạo migration: `alembic revision --autogenerate -m "add_users_table"`

### Task 2.2: Security utilities
- [ ] Tạo `app/core/security.py`:
  - `hash_password(password: str) -> str`
  - `verify_password(plain: str, hashed: str) -> bool`
  - `create_access_token(data: dict) -> str`
  - `create_refresh_token(data: dict) -> str`
  - `decode_token(token: str) -> dict`

### Task 2.3: Auth schemas
- [ ] Tạo `app/schemas/auth.py`:
  - `RegisterRequest` (username, email, password)
  - `LoginRequest` (username, password)
  - `TokenResponse` (access_token, refresh_token, token_type)
  - `RefreshRequest` (refresh_token)
- [ ] Tạo `app/schemas/user.py`:
  - `UserResponse`
  - `UserPublicResponse` (không có email)
  - `UpdateProfileRequest`

### Task 2.4: User service
- [ ] Tạo `app/services/user_service.py`:
  - `create_user(data) -> User`
  - `get_by_username(username) -> User | None`
  - `get_by_email(email) -> User | None`
  - `get_by_id(user_id) -> User`
  - `update_profile(user_id, data) -> User`
  - `update_password(user_id, old_pw, new_pw) -> bool`
  - `set_online_status(user_id, is_online) -> None`

### Task 2.5: Auth service
- [ ] Tạo `app/services/auth_service.py`:
  - `register(data) -> TokenResponse`
  - `login(data) -> TokenResponse`
  - `refresh_token(token) -> TokenResponse`
  - `logout(token) -> None`

### Task 2.6: Auth API routes
- [ ] Tạo `app/api/auth.py`:
  - `POST /api/v1/auth/register`
  - `POST /api/v1/auth/login`
  - `POST /api/v1/auth/refresh`
  - `POST /api/v1/auth/logout`
- [ ] Tạo `app/api/router.py` — gộp tất cả routers

### Task 2.7: User API routes
- [ ] Tạo `app/api/users.py`:
  - `GET /api/v1/users/me`
  - `PATCH /api/v1/users/me`
  - `PUT /api/v1/users/me/password`
  - `GET /api/v1/users/{user_id}`

### Task 2.8: Auth dependency
- [ ] Tạo dependency `get_current_user` trong `app/dependencies.py`
- [ ] Parse JWT từ header `Authorization: Bearer <token>`
- [ ] Raise 401 nếu token không hợp lệ

### Task 2.9: Tests cho Auth & User
- [ ] `tests/test_auth.py`:
  - Test register thành công
  - Test register trùng username/email
  - Test login thành công
  - Test login sai password
  - Test refresh token
  - Test logout
- [ ] `tests/test_users.py`:
  - Test get profile
  - Test update profile
  - Test change password

---

## Phase 3: Rooms

### Task 3.1: Room & RoomMember models
- [ ] Tạo `app/models/room.py` — SQLAlchemy model `Room`
- [ ] Tạo `app/models/room_member.py` — SQLAlchemy model `RoomMember`
- [ ] Relationships: Room.members, RoomMember.user, RoomMember.room
- [ ] Tạo migration

### Task 3.2: Room schemas
- [ ] Tạo `app/schemas/room.py`:
  - `CreateRoomRequest` (name, description)
  - `UpdateRoomRequest` (name, description)
  - `RoomResponse`
  - `RoomDetailResponse` (bao gồm members)
  - `RoomMemberResponse`
  - `JoinRoomRequest` (invite_code)

### Task 3.3: Room service
- [ ] Tạo `app/services/room_service.py`:
  - `create_room(created_by, data) -> Room`
  - `get_room(room_id) -> Room`
  - `get_user_rooms(user_id, page, per_page, search) -> Paginated[Room]`
  - `update_room(room_id, user_id, data) -> Room`
  - `delete_room(room_id, user_id) -> None`
  - `join_room(user_id, invite_code) -> Room`
  - `leave_room(room_id, user_id) -> None`
  - `kick_member(room_id, admin_id, user_id) -> None`
  - `generate_invite_code(room_id) -> str`
  - `get_room_members(room_id) -> list[RoomMember]`
  - `is_member(room_id, user_id) -> bool`
  - `is_admin(room_id, user_id) -> bool`

### Task 3.4: Room API routes
- [ ] Tạo `app/api/rooms.py`:
  - `POST /api/v1/rooms`
  - `GET /api/v1/rooms`
  - `GET /api/v1/rooms/{room_id}`
  - `PATCH /api/v1/rooms/{room_id}`
  - `DELETE /api/v1/rooms/{room_id}`
  - `POST /api/v1/rooms/join`
  - `POST /api/v1/rooms/{room_id}/leave`
  - `POST /api/v1/rooms/{room_id}/invite-code`
  - `DELETE /api/v1/rooms/{room_id}/members/{user_id}`

### Task 3.5: Tests cho Rooms
- [ ] `tests/test_rooms.py`:
  - Test create room
  - Test get user rooms
  - Test join room bằng invite code
  - Test join room trùng
  - Test leave room
  - Test update room (admin only)
  - Test delete room (owner only)
  - Test kick member

---

## Phase 4: Messages

### Task 4.1: Message model
- [ ] Tạo `app/models/message.py` — SQLAlchemy model `Message`
- [ ] Tạo migration

### Task 4.2: Message schemas
- [ ] Tạo `app/schemas/message.py`:
  - `MessageResponse`
  - `MessageListResponse` (paginated)

### Task 4.3: Message service
- [ ] Tạo `app/services/message_service.py`:
  - `create_message(room_id, user_id, content, message_type, file_url, file_name) -> Message`
  - `get_messages(room_id, page, per_page, before_id, search) -> Paginated[Message]`
  - `get_messages_after(room_id, after_id) -> list[Message]` — cho sync
  - `update_status(message_id, status) -> None`

### Task 4.4: Message API routes
- [ ] Tạo `app/api/messages.py`:
  - `GET /api/v1/messages/{room_id}/messages`
  - `POST /api/v1/messages/{room_id}/messages/file` (multipart)

### Task 4.5: File storage utility
- [ ] Tạo `app/utils/file_storage.py`:
  - `save_file(file: UploadFile, room_id: int) -> tuple[str, str]` — trả về (file_url, file_name)
  - `get_file_path(file_url: str) -> Path`
  - Validate file size (max 10MB)
  - Validate file type (image, document)
  - Tạo tên file unique (UUID)

### Task 4.6: Tests cho Messages
- [ ] `tests/test_messages.py`:
  - Test get messages (phân trang)
  - Test get messages with before_id
  - Test search messages
  - Test upload file
  - Test upload file quá lớn

---

## Phase 5: WebSocket

### Task 5.1: WebSocket protocol
- [ ] Tạo `app/ws/protocol.py`:
  - Define tất cả WS message types (ClientEvent, ServerEvent)
  - Pydantic models cho mỗi event type
  - Serialize/deserialize functions

### Task 5.2: Connection Manager
- [ ] Tạo `app/ws/manager.py` — `ConnectionManager` class:
  - `connect(user_id, room_id, websocket)`
  - `disconnect(user_id, room_id)`
  - `disconnect_all(user_id)` — khi user mất kết nối
  - `broadcast(room_id, message, exclude_user=None)`
  - `send_personal(user_id, message)`
  - `get_online_members(room_id) -> list[dict]`
  - Data structures:
    - `rooms: dict[int, dict[int, WebSocket]]` — room_id -> {user_id -> ws}
    - `user_rooms: dict[int, set[int]]` — user_id -> set of room_ids

### Task 5.3: Presence service
- [ ] Tạo `app/services/presence_service.py`:
  - `user_connected(user_id)` — set online, broadcast
  - `user_disconnected(user_id)` — set offline, broadcast, cleanup
  - `get_online_users(room_id) -> list[int]`

### Task 5.4: WebSocket handler
- [ ] Tạo `app/ws/handler.py`:
  - WebSocket endpoint: `/ws`
  - Authenticate via query param `?token=xxx`
  - Parse incoming messages, route to appropriate handler
  - Handle each event type:
    - `join_room` → load unread count, broadcast user_joined
    - `leave_room` → broadcast user_left
    - `send_message` → save to DB, broadcast new_message
    - `typing` → broadcast typing_indicator
    - `stop_typing` → broadcast typing_indicator (false)
    - `sync_messages` → load missed messages
    - `mark_read` → update unread_count
    - `ping` → respond pong
  - Handle disconnect cleanup

### Task 5.5: Unread tracking
- [ ] Khi user nhận `new_message` mà không ở phòng đó → tăng `unread_count` trong `room_members`
- [ ] Khi user gửi `mark_read` → reset `unread_count`, update `last_read_message_id`
- [ ] Gửi `unread_update` event cho client

### Task 5.6: Tests cho WebSocket
- [ ] `tests/test_websocket.py`:
  - Test connect với valid token
  - Test connect với invalid token (reject)
  - Test join_room
  - Test send_message → nhận new_message
  - Test typing indicator
  - Test disconnect cleanup
  - Test sync_messages

---

## Phase 6: Middleware & Error Handling

### Task 6.1: Custom exceptions
- [ ] Tạo `app/core/exceptions.py`:
  - `AppException(code, message, status_code)`
  - Các exception con: `NotFoundError`, `AuthError`, `ForbiddenError`, `ConflictError`, `ValidationError`
- [ ] Register exception handler trong `main.py`

### Task 6.2: CORS middleware
- [ ] Configure CORS trong `main.py` cho phép client Swift kết nối

### Task 6.3: Rate limiting middleware
- [ ] Implement rate limiting (in-memory hoặc Redis-backed)
- [ ] Áp dụng cho REST API và WebSocket

### Task 6.4: Request logging
- [ ] Log mỗi request: method, path, status_code, duration
- [ ] Log WebSocket events

### Task 6.5: App factory
- [ ] Tạo `app/main.py` — FastAPI app factory:
  - Include all routers
  - Register middleware
  - Register exception handlers
  - Startup/shutdown events (DB connection)
  - Health check endpoint: `GET /health`

---

## Phase 7: Polish & Documentation

### Task 7.1: API documentation
- [ ] Verify Swagger UI hoạt động tại `/docs`
- [ ] Verify ReDoc tại `/redoc`
- [ ] Thêm descriptions cho tất cả endpoints

### Task 7.2: Seed data
- [ ] Tạo script `scripts/seed.py` để tạo test data:
  - 5 users mẫu
  - 3 rooms mẫu
  - Một số tin nhắn mẫu

### Task 7.3: README
- [ ] Cập nhật `README.md` với:
  - Hướng dẫn cài đặt
  - Hướng dẫn chạy migration
  - Hướng dẫn chạy server
  - Hướng dẫn chạy tests
  - API endpoints summary

---

## Ưu tiên thực hiện

```
Phase 1 (Setup)          → Ngày 1
Phase 2 (Auth + User)    → Ngày 2-3
Phase 3 (Rooms)          → Ngày 4-5
Phase 4 (Messages)       → Ngày 6-7
Phase 5 (WebSocket)      → Ngày 8-10
Phase 6 (Middleware)      → Ngày 11
Phase 7 (Polish)         → Ngày 12
```

## Checklist trước khi hoàn thành

- [ ] Tất cả tests pass (`pytest`)
- [ ] Migration chạy sạch (`alembic upgrade head`)
- [ ] Swagger UI đầy đủ endpoints
- [ ] Không hardcoded secrets
- [ ] Error responses đúng format
- [ ] WebSocket connect/disconnect xử lý đúng
- [ ] Rate limiting hoạt động
- [ ] File upload validation hoạt động
