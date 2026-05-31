# REST API Specification
## Backend ChatRoom — FastAPI

---

## Quy ước chung

### Base URL
```
http://localhost:8000/api/v1
```

### Headers
```
Content-Type: application/json
Authorization: Bearer <access_token>  (trừ auth endpoints)
```

### Response format
```json
{
  "success": true,
  "data": { ... },
  "error": null
}
```

### Pagination format
```json
{
  "success": true,
  "data": {
    "items": [...],
    "total": 100,
    "page": 1,
    "per_page": 20,
    "total_pages": 5
  }
}
```

---

## 1. Auth — `/api/v1/auth`

### POST `/register`
Tạo tài khoản mới.

**Request body:**
```json
{
  "username": "string (3-30 chars, alphanumeric + underscore)",
  "email": "string (valid email)",
  "password": "string (8-128 chars, must contain uppercase, lowercase, digit)"
}
```

**Response 201:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "username": "john_doe",
      "email": "john@example.com",
      "display_name": "john_doe",
      "created_at": "2026-05-31T10:00:00Z"
    },
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "token_type": "bearer"
  }
}
```

**Errors:**
- 409 `USERNAME_EXISTS`: Username đã tồn tại
- 409 `EMAIL_EXISTS`: Email đã được sử dụng
- 422 `VALIDATION_ERROR`: Dữ liệu không hợp lệ

---

### POST `/login`
Đăng nhập.

**Request body:**
```json
{
  "username": "string (username hoặc email)",
  "password": "string"
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "user": { ... },
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "token_type": "bearer"
  }
}
```

**Errors:**
- 401 `INVALID_CREDENTIALS`: Sai username/email hoặc password

---

### POST `/refresh`
Làm mới access token.

**Request body:**
```json
{
  "refresh_token": "string"
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "token_type": "bearer"
  }
}
```

**Errors:**
- 401 `INVALID_TOKEN`: Token không hợp lệ hoặc đã hết hạn
- 401 `TOKEN_REVOKED`: Token đã bị revoke

---

### POST `/logout`
Đăng xuất (revoke refresh token).

**Request body:**
```json
{
  "refresh_token": "string"
}
```

**Response 200:**
```json
{
  "success": true,
  "data": { "message": "Đăng xuất thành công" }
}
```

---

## 2. Users — `/api/v1/users`

### GET `/me`
Lấy thông tin user hiện tại (cần auth).

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "display_name": "John Doe",
    "avatar_url": null,
    "is_online": true,
    "created_at": "2026-05-31T10:00:00Z"
  }
}
```

---

### PATCH `/me`
Cập nhật profile (cần auth).

**Request body:**
```json
{
  "display_name": "string (1-50 chars, optional)",
  "avatar_url": "string (valid URL, optional)"
}
```

**Response 200:** Updated user object.

---

### PUT `/me/password`
Đổi mật khẩu (cần auth).

**Request body:**
```json
{
  "current_password": "string",
  "new_password": "string (8-128 chars)"
}
```

**Response 200:**
```json
{
  "success": true,
  "data": { "message": "Đổi mật khẩu thành công" }
}
```

**Errors:**
- 401 `WRONG_PASSWORD`: Mật khẩu hiện tại sai

---

### GET `/{user_id}`
Lấy thông tin user khác (cần auth).

**Response 200:** Public user object (không có email).

---

## 3. Rooms — `/api/v1/rooms`

### POST `/`
Tạo phòng chat mới (cần auth).

**Request body:**
```json
{
  "name": "string (1-100 chars)",
  "description": "string (0-500 chars, optional)"
}
```

**Response 201:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "General",
    "description": "Phòng chat chung",
    "invite_code": "abc123xyz",
    "created_by": 1,
    "member_count": 1,
    "created_at": "2026-05-31T10:00:00Z"
  }
}
```

---

### GET `/`
Lấy danh sách phòng đã tham gia (cần auth).

**Query params:**
- `page` (int, default 1)
- `per_page` (int, default 20, max 50)
- `search` (string, optional) — tìm theo tên phòng

**Response 200:** Paginated list of rooms.

---

### GET `/{room_id}`
Lấy chi tiết phòng (cần auth, phải là thành viên).

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "General",
    "description": "Phòng chat chung",
    "invite_code": "abc123xyz",
    "created_by": 1,
    "members": [
      {
        "user_id": 1,
        "username": "john",
        "display_name": "John",
        "role": "admin",
        "is_online": true,
        "joined_at": "2026-05-31T10:00:00Z"
      }
    ],
    "created_at": "2026-05-31T10:00:00Z"
  }
}
```

---

### PATCH `/{room_id}`
Chỉnh sửa phòng (cần auth, phải là admin).

**Request body:**
```json
{
  "name": "string (optional)",
  "description": "string (optional)"
}
```

**Response 200:** Updated room object.

---

### DELETE `/{room_id}`
Xóa phòng (cần auth, phải là owner).

**Response 200:**
```json
{
  "success": true,
  "data": { "message": "Phòng đã được xóa" }
}
```

---

### POST `/join`
Tham gia phòng bằng invite code (cần auth).

**Request body:**
```json
{
  "invite_code": "string"
}
```

**Response 200:** Room object.

**Errors:**
- 404 `INVALID_INVITE_CODE`: Mã mời không hợp lệ
- 409 `ALREADY_MEMBER`: Đã là thành viên

---

### POST `/{room_id}/leave`
Rời khỏi phòng (cần auth).

**Response 200:**
```json
{
  "success": true,
  "data": { "message": "Đã rời khỏi phòng" }
}
```

---

### POST `/{room_id}/invite-code`
Tạo invite code mới (cần auth, phải là admin).

**Response 201:**
```json
{
  "success": true,
  "data": {
    "invite_code": "new_code_123"
  }
}
```

---

### DELETE `/{room_id}/members/{user_id}`
Kick thành viên (cần auth, phải là admin).

**Response 200:**
```json
{
  "success": true,
  "data": { "message": "Đã xóa thành viên khỏi phòng" }
}
```

---

## 4. Messages — `/api/v1/messages`

### GET `/{room_id}/messages`
Lấy lịch sử tin nhắn (cần auth, phải là thành viên).

**Query params:**
- `page` (int, default 1)
- `per_page` (int, default 50, max 100)
- `before_id` (int, optional) — lấy tin nhắn trước message_id này
- `search` (string, optional) — tìm trong nội dung tin nhắn

**Response 200:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 1,
        "room_id": 1,
        "user_id": 1,
        "username": "john",
        "display_name": "John",
        "content": "Hello everyone!",
        "message_type": "text",
        "file_url": null,
        "file_name": null,
        "status": "delivered",
        "created_at": "2026-05-31T10:00:00Z"
      }
    ],
    "total": 150,
    "page": 1,
    "per_page": 50,
    "total_pages": 3
  }
}
```

---

### POST `/{room_id}/messages/file`
Gửi tin nhắn có file đính kèm (cần auth).

**Request:** `multipart/form-data`
- `file` (File, max 10MB)
- `content` (string, optional — caption)

**Response 201:**
```json
{
  "success": true,
  "data": {
    "id": 2,
    "room_id": 1,
    "message_type": "file",
    "file_url": "/uploads/rooms/1/abc123.pdf",
    "file_name": "document.pdf",
    "content": "Xem file này",
    ...
  }
}
```

---

## 5. Files — `/api/v1/files`

### GET `/uploads/{path}`
Download file đính kèm (cần auth).

**Response:** File binary với Content-Type phù hợp.

---

## WebSocket API

Xem file `websocket-protocol.md` để biết chi tiết WebSocket protocol.
