# Database Schema
## Backend ChatRoom — PostgreSQL

---

## 1. ER Diagram (mô tả)

```
┌──────────┐       ┌──────────────┐       ┌──────────┐
│  users   │──1:N──│ room_members │──N:1──│  rooms   │
└──────────┘       └──────────────┘       └──────────┘
     │                                        │
     │ 1:N                                    │ 1:N
     │                                        │
     ▼                                        ▼
┌──────────┐                            ┌──────────┐
│messages │──────────N:1────────────────│messages  │
└──────────┘                            └──────────┘
     │
     │ 1:N
     ▼
┌──────────────┐
│refresh_tokens│
└──────────────┘
```

---

## 2. Tables

### `users`

| Column | Type | Constraints | Mô tả |
|---|---|---|---|
| id | SERIAL | PK | ID tự tăng |
| username | VARCHAR(30) | UNIQUE, NOT NULL | Tên đăng nhập |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Email |
| password_hash | VARCHAR(255) | NOT NULL | Mật khẩu đã hash |
| display_name | VARCHAR(50) | NOT NULL | Tên hiển thị |
| avatar_url | VARCHAR(500) | NULLABLE | URL avatar |
| is_online | BOOLEAN | DEFAULT false | Trạng thái online |
| last_seen_at | TIMESTAMP | NULLABLE | Lần online cuối |
| created_at | TIMESTAMP | DEFAULT NOW() | Thời gian tạo |
| updated_at | TIMESTAMP | DEFAULT NOW() | Thời gian cập nhật |

**Indexes:**
- `idx_users_username` — UNIQUE trên username
- `idx_users_email` — UNIQUE trên email

---

### `rooms`

| Column | Type | Constraints | Mô tả |
|---|---|---|---|
| id | SERIAL | PK | ID tự tăng |
| name | VARCHAR(100) | NOT NULL | Tên phòng |
| description | VARCHAR(500) | NULLABLE | Mô tả phòng |
| invite_code | VARCHAR(20) | UNIQUE, NOT NULL | Mã mời |
| created_by | INTEGER | FK → users.id, NOT NULL | Người tạo |
| created_at | TIMESTAMP | DEFAULT NOW() | Thời gian tạo |
| updated_at | TIMESTAMP | DEFAULT NOW() | Thời gian cập nhật |

**Indexes:**
- `idx_rooms_invite_code` — UNIQUE trên invite_code
- `idx_rooms_created_by` — trên created_by

---

### `room_members`

| Column | Type | Constraints | Mô tả |
|---|---|---|---|
| id | SERIAL | PK | ID tự tăng |
| room_id | INTEGER | FK → rooms.id ON DELETE CASCADE, NOT NULL | Phòng |
| user_id | INTEGER | FK → users.id ON DELETE CASCADE, NOT NULL | Thành viên |
| role | VARCHAR(10) | DEFAULT 'member', NOT NULL | Vai trò (admin/member) |
| unread_count | INTEGER | DEFAULT 0, NOT NULL | Số tin nhắn chưa đọc |
| last_read_message_id | INTEGER | NULLABLE | ID tin nhắn đã đọc cuối |
| joined_at | TIMESTAMP | DEFAULT NOW() | Thời gian tham gia |

**Constraints:**
- UNIQUE(room_id, user_id) — mỗi user chỉ tham gia phòng 1 lần

**Indexes:**
- `idx_room_members_room_id` — trên room_id
- `idx_room_members_user_id` — trên user_id
- `idx_room_members_composite` — UNIQUE trên (room_id, user_id)

---

### `messages`

| Column | Type | Constraints | Mô tả |
|---|---|---|---|
| id | SERIAL (BIGSERIAL) | PK | ID tự tăng |
| room_id | INTEGER | FK → rooms.id ON DELETE CASCADE, NOT NULL | Phòng chat |
| user_id | INTEGER | FK → users.id ON DELETE SET NULL, NULLABLE | Người gửi |
| content | TEXT | NOT NULL | Nội dung tin nhắn |
| message_type | VARCHAR(10) | DEFAULT 'text', NOT NULL | Loại (text/file) |
| file_url | VARCHAR(500) | NULLABLE | URL file đính kèm |
| file_name | VARCHAR(255) | NULLABLE | Tên file gốc |
| status | VARCHAR(15) | DEFAULT 'sent', NOT NULL | Trạng thái (sent/delivered/read) |
| created_at | TIMESTAMP | DEFAULT NOW() | Thời gian gửi |

**Indexes:**
- `idx_messages_room_id` — trên room_id
- `idx_messages_created_at` — trên created_at
- `idx_messages_room_created` — composite (room_id, created_at DESC) — query chính khi load lịch sử

---

### `refresh_tokens`

| Column | Type | Constraints | Mô tả |
|---|---|---|---|
| id | SERIAL | PK | ID tự tăng |
| user_id | INTEGER | FK → users.id ON DELETE CASCADE, NOT NULL | Chủ token |
| token_hash | VARCHAR(255) | UNIQUE, NOT NULL | Hash của refresh token |
| expires_at | TIMESTAMP | NOT NULL | Thời gian hết hạn |
| created_at | TIMESTAMP | DEFAULT NOW() | Thời gian tạo |
| revoked_at | TIMESTAMP | NULLABLE | Thời gian revoke |

**Indexes:**
- `idx_refresh_tokens_hash` — UNIQUE trên token_hash
- `idx_refresh_tokens_user` — trên user_id

---

## 3. Relationships

```
users 1:N room_members (user tham gia nhiều phòng)
rooms 1:N room_members (phòng có nhiều thành viên)
users 1:N messages (user gửi nhiều tin nhắn)
rooms 1:N messages (phòng có nhiều tin nhắn)
users 1:N refresh_tokens (user có nhiều refresh tokens)
rooms N:1 users (created_by — người tạo phòng)
```

## 4. Cascade Rules

- Xóa **user** → cascade xóa room_members, refresh_tokens. Messages: SET NULL user_id
- Xóa **room** → cascade xóa room_members, messages
- Xóa **room_member** → không ảnh hưởng gì khác

## 5. Migration Strategy

Sử dụng **Alembic** cho database migrations:

```
alembic init alembic
alembic revision --autogenerate -m "initial_schema"
alembic upgrade head
```

Thứ tự tạo tables:
1. `users`
2. `rooms`
3. `room_members`
4. `messages`
5. `refresh_tokens`
