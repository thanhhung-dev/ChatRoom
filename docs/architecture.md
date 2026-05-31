# Kiến trúc Hệ thống — Backend ChatRoom

---

## 1. Tổng quan kiến trúc

```
┌─────────────┐       ┌─────────────────────────────────────────┐
│             │  REST  │         FastAPI Application             │
│  Swift      │◄──────►│                                         │
│  Client     │        │  ┌───────────┐  ┌──────────────────┐   │
│             │  WS    │  │ REST API  │  │ WebSocket Server │   │
│             │◄──────►│  │ Handlers  │  │ (Connection Mgr) │   │
└─────────────┘        │  └─────┬─────┘  └────────┬─────────┘   │
                       │        │                  │             │
                       │  ┌─────▼──────────────────▼─────────┐  │
                       │  │        Service Layer              │  │
                       │  │  (AuthService, RoomService,       │  │
                       │  │   MessageService, PresenceService)│  │
                       │  └─────┬──────────────────┬─────────┘  │
                       │        │                  │             │
                       │  ┌─────▼─────┐    ┌──────▼──────────┐  │
                       │  │ SQLAlchemy │    │  File Storage   │  │
                       │  │ (Async)    │    │  (Local/S3)     │  │
                       │  └─────┬─────┘    └─────────────────┘  │
                       └────────┼────────────────────────────────┘
                                │
                       ┌────────▼────────┐
                       │   PostgreSQL    │
                       │   Database      │
                       └─────────────────┘
```

## 2. Cấu trúc thư mục

```
backend/
├── alembic/                    # Database migrations
│   ├── versions/
│   └── env.py
├── alembic.ini
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app factory
│   ├── config.py               # Settings (Pydantic Settings)
│   ├── dependencies.py         # FastAPI dependencies (get_db, get_current_user)
│   │
│   ├── models/                 # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── base.py             # Base model, mixins
│   │   ├── user.py
│   │   ├── room.py
│   │   ├── message.py
│   │   └── room_member.py
│   │
│   ├── schemas/                # Pydantic schemas (request/response)
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── user.py
│   │   ├── room.py
│   │   ├── message.py
│   │   └── common.py           # Pagination, error responses
│   │
│   ├── api/                    # REST API routes
│   │   ├── __init__.py
│   │   ├── router.py           # Root router
│   │   ├── auth.py
│   │   ├── users.py
│   │   ├── rooms.py
│   │   └── messages.py
│   │
│   ├── services/               # Business logic
│   │   ├── __init__.py
│   │   ├── auth_service.py
│   │   ├── user_service.py
│   │   ├── room_service.py
│   │   ├── message_service.py
│   │   └── presence_service.py
│   │
│   ├── ws/                     # WebSocket handling
│   │   ├── __init__.py
│   │   ├── manager.py          # ConnectionManager
│   │   ├── handler.py          # WebSocket endpoint + message routing
│   │   ├── protocol.py         # WS message types, serialization
│   │   └── events.py           # Event types definitions
│   │
│   ├── core/                   # Cross-cutting concerns
│   │   ├── __init__.py
│   │   ├── security.py         # JWT encode/decode, password hash
│   │   ├── exceptions.py       # Custom exception classes
│   │   └── middleware.py       # CORS, rate limit, logging
│   │
│   └── utils/                  # Utilities
│       ├── __init__.py
│       ├── file_storage.py     # File upload/download
│       └── pagination.py       # Pagination helpers
│
├── tests/
│   ├── conftest.py
│   ├── test_auth.py
│   ├── test_rooms.py
│   ├── test_messages.py
│   └── test_websocket.py
│
├── uploads/                    # Uploaded files (local storage)
├── requirements.txt
├── .env.example
└── README.md
```

## 3. Luồng xử lý chính

### 3.1 Authentication Flow

```
Client                    Server                    DB
  │                         │                        │
  │── POST /auth/register ──►│                        │
  │                         │── hash password ──────►│
  │                         │◄── user created ───────│
  │◄── 201 Created ────────│                        │
  │                         │                        │
  │── POST /auth/login ────►│                        │
  │                         │── verify password ────►│
  │                         │◄── user found ─────────│
  │◄── JWT tokens ─────────│                        │
  │                         │                        │
  │── POST /auth/refresh ──►│                        │
  │                         │── validate refresh ───►│
  │◄── New access token ───│                        │
```

### 3.2 WebSocket Connection Flow

```
Client                    Server                    DB
  │                         │                        │
  │── GET /ws?token=xxx ───►│                        │
  │                         │── validate JWT ────────│
  │                         │── register connection ─│
  │◄── WS connected ───────│                        │
  │                         │                        │
  │── {type:"join_room",   ►│                        │
  │    room_id: 1}          │── load unread count ──►│
  │◄── {type:"room_joined",│◄── unread count ───────│
  │    members:[...]}       │                        │
  │                         │── broadcast join ──────│
  │                         │                        │
  │── {type:"send_message",►│                        │
  │    room_id:1,           │── save message ───────►│
  │    content:"hello"}     │◄── message saved ──────│
  │◄── {type:"message_sent",│                        │
  │    message:{...}}       │── broadcast to room ───│
  │                         │                        │
  │── {type:"typing",      ►│                        │
  │    room_id:1}           │── broadcast typing ────│
  │                         │                        │
  │── WS disconnect ───────►│                        │
  │                         │── update presence ─────│
  │                         │── broadcast offline ───│
```

### 3.3 Message Reconnection Sync

```
Client                    Server
  │                         │
  │── WS connect ─────────►│
  │                         │
  │── {type:"sync",        ►│
  │    room_id:1,           │
  │    last_message_id:42}  │
  │                         │── query messages where id > 42
  │◄── {type:"sync_messages",│
  │    messages:[43,44,45]} │
  │                         │
```

## 4. Kết nối WebSocket quản lý

### ConnectionManager

Quản lý tất cả WebSocket connections theo cấu trúc:

```
connections: dict[room_id, dict[user_id, WebSocket]]
user_rooms: dict[user_id, set[room_id]]
```

Các operation chính:
- `connect(user_id, room_id, websocket)` — thêm connection
- `disconnect(user_id, room_id)` — xóa connection
- `broadcast(room_id, message, exclude_user=None)` — gửi cho tất cả trong phòng
- `send_personal(user_id, message)` — gửi cho 1 user (mọi phòng họ đang kết nối)
- `get_room_members(room_id)` → list online members

## 5. Auth Strategy

### JWT Tokens

- **Access token**: 15 phút, chứa `user_id`, `username`
- **Refresh token**: 7 ngày, lưu trong DB (có thể revoke)
- **WS auth**: Client gửi token qua query param `?token=xxx` khi handshake

### Password

- Hash bằng `bcrypt` (passlib)
- Salt rounds: 12

## 6. Error Handling Strategy

Tất cả API responses dùng format thống nhất:

```json
// Success
{
  "success": true,
  "data": { ... },
  "error": null
}

// Error
{
  "success": false,
  "data": null,
  "error": {
    "code": "ROOM_NOT_FOUND",
    "message": "Phòng chat không tồn tại"
  }
}
```

HTTP status codes:
- 200: Thành công
- 201: Tạo mới thành công
- 400: Validation error
- 401: Chưa xác thực
- 403: Không có quyền
- 404: Không tìm thấy
- 409: Conflict (username đã tồn tại, đã là thành viên)
- 422: Unprocessable entity
- 429: Rate limit exceeded
- 500: Server error

## 7. Rate Limiting

| Endpoint | Limit |
|---|---|
| POST /auth/register | 5/phút |
| POST /auth/login | 10/phút |
| POST /messages (WS) | 30/phút |
| GET /messages | 60/phút |
| File upload | 10/giờ |

## 8. Database Connection Pool

```
SQLAlchemy async engine:
- pool_size: 20
- max_overflow: 10
- pool_timeout: 30
- pool_recycle: 1800
```
