# Product Requirements Document (PRD)
## Hệ thống Chat Room Thời Gian Thực — Backend

---

## 1. Tổng quan

Xây dựng backend cho hệ thống chat room thời gian thực sử dụng **Python FastAPI** + **WebSocket**. Backend phục vụ client Swift (iOS/macOS) qua REST API và WebSocket.

## 2. Phạm vi

Chỉ bao gồm **server-side**:
- REST API (auth, rooms, users, messages)
- WebSocket server (real-time messaging)
- Database (PostgreSQL)
- File storage (local hoặc S3-compatible)
- Background tasks (cleanup, presence tracking)

**Không bao gồm:** Client Swift, UI/UX design.

## 3. Stack kỹ thuật

| Thành phần | Lựa chọn |
|---|---|
| Framework | FastAPI |
| ASGI Server | Uvicorn |
| Database | PostgreSQL 15+ |
| ORM | SQLAlchemy 2.0 (async) + Alembic |
| WebSocket | FastAPI native (starlette.websockets) |
| Auth | JWT (access + refresh token) |
| Password hashing | bcrypt (passlib) |
| File storage | Local filesystem (phase 1), S3-compatible (phase 2) |
| Task queue | BackgroundTasks (FastAPI) hoặc asyncio |
| Validation | Pydantic v2 |
| Testing | pytest + pytest-asyncio + httpx |

## 4. Yêu cầu phi chức năng

| Yêu cầu | Mục tiêu |
|---|---|
| Concurrent connections | 1000+ WebSocket connections |
| Message latency | < 100ms (server processing) |
| API response time | < 200ms (95th percentile) |
| Uptime | 99.5% |
| Message persistence | 100% tin nhắn được lưu |
| Reconnection sync | Client nhận được tin nhắn missed khi reconnect |

## 5. Actors (Người dùng hệ thống)

| Actor | Mô tả |
|---|---|
| Guest | Chưa đăng nhập, chỉ xem trang login/register |
| User | Đã đăng nhập, tham gia phòng chat, gửi tin nhắn |
| Room Admin | Người tạo phòng, có quyền chỉnh sửa/xóa phòng |

## 6. Tính năng chi tiết

### 6.1 Quản lý người dùng

| ID | Tính năng | Ưu tiên |
|---|---|---|
| U-01 | Đăng ký tài khoản (username, email, password) | P0 |
| U-02 | Đăng nhập (username/email + password) → nhận JWT | P0 |
| U-03 | Đăng xuất (invalidate refresh token) | P0 |
| U-04 | Refresh access token | P0 |
| U-05 | Xem profile người dùng | P1 |
| U-06 | Cập nhật profile (display_name, avatar) | P1 |
| U-07 | Đổi mật khẩu | P1 |

### 6.2 Quản lý phòng chat

| ID | Tính năng | Ưu tiên |
|---|---|---|
| R-01 | Tạo phòng chat mới (name, description) | P0 |
| R-02 | Tham gia phòng bằng invite code | P0 |
| R-03 | Tham gia phòng bằng tìm kiếm | P1 |
| R-04 | Rời khỏi phòng | P0 |
| R-05 | Xem danh sách phòng đã tham gia | P0 |
| R-06 | Chỉnh sửa tên/mô tả phòng (admin) | P1 |
| R-07 | Xóa phòng (admin/owner) | P1 |
| R-08 | Quản lý thành viên phòng (kick, role) | P2 |
| R-09 | Tạo invite code mới | P0 |

### 6.3 Nhắn tin thời gian thực

| ID | Tính năng | Ưu tiên |
|---|---|---|
| M-01 | Gửi/nhận tin nhắn văn bản qua WebSocket | P0 |
| M-02 | Hiển thị thời gian gửi tin nhắn | P0 |
| M-03 | Trạng thái tin nhắn (sent, delivered) | P1 |
| M-04 | Tải lịch sử tin nhắn (phân trang) | P0 |
| M-05 | Gửi file đính kèm (image, document) | P1 |
| M-06 | Typing indicator | P1 |
| M-07 | Thông báo user join/leave phòng | P0 |
| M-08 | Đánh dấu tin nhắn đã đọc (read receipts) | P2 |

### 6.4 Trạng thái online/offline

| ID | Tính năng | Ưu tiên |
|---|---|---|
| P-01 | Hiển thị user online trong phòng | P0 |
| P-02 | Cập nhật trạng thái khi disconnect | P0 |
| P-03 | Heartbeat để phát hiện stale connections | P0 |

### 6.5 Tìm kiếm

| ID | Tính năng | Ưu tiên |
|---|---|---|
| S-01 | Tìm phòng chat theo tên | P1 |
| S-02 | Tìm tin nhắn trong phòng | P2 |

### 6.6 Thông báo

| ID | Tính năng | Ưu tiên |
|---|---|---|
| N-01 | Thông báo tin nhắn mới khi ở phòng khác (qua WebSocket) | P0 |
| N-02 | Badge số tin nhắn chưa đọc | P1 |

### 6.7 Lưu trữ và đồng bộ

| ID | Tính năng | Ưu tiên |
|---|---|---|
| D-01 | Lưu lịch sử tin nhắn vào PostgreSQL | P0 |
| D-02 | Đồng bộ tin nhắn khi reconnect | P0 |
| D-03 | Lưu file đính kèm | P1 |

---

## 7. Ràng buộc

- Password phải hash bằng bcrypt, KHÔNG lưu plain text
- JWT access token hết hạn sau 15 phút, refresh token 7 ngày
- Tin nhắn tối đa 5000 ký tự
- File đính kèm tối đa 10MB
- Mỗi user tham gia tối đa 50 phòng
- Rate limit: 100 requests/phút cho REST API

## 8. Phụ thuộc

- Python 3.11+
- PostgreSQL 15+
- pip hoặc poetry (package management)
