# BoxChat (ChatRoom)

BoxChat là một ứng dụng Mạng xã hội & Nhắn tin thời gian thực (Real-time Chat) toàn diện. Dự án bao gồm ứng dụng di động native trên iOS và hệ thống máy chủ (Backend) hiệu năng cao xử lý qua WebSocket.

## ✨ Tính năng nổi bật

### 💬 Nhắn tin (Chat)
* **Real-time WebSocket:** Gửi/nhận tin nhắn ngay lập tức không có độ trễ.
* **Đa phương tiện:** Hỗ trợ gửi ảnh, video, tài liệu và **tin nhắn thoại (voice)**.
* **Smart Replies:** Tích hợp AI/Logic gợi ý câu trả lời nhanh.
* **Khám phá P2P:** Tìm kiếm bạn bè gần đây qua mạng nội bộ (UDP Broadcast).
* **Quét mã QR:** Thêm bạn bè, tham gia nhóm chat nhanh chóng bằng Camera.

### 🌐 Mạng xã hội (Social Feed)
* **Bảng tin (Explore):** Đăng status, đính kèm nhiều hình ảnh/video.
* **Tương tác:** Thích (React) và Bình luận (Comment) thời gian thực trên bài viết.
* **Giao diện hiện đại:** Hỗ trợ Dark Mode, thiết kế theo chuẩn Design System mới (BCTheme) mang lại trải nghiệm mượt mà, cao cấp.

### 🔒 Xác thực & Cá nhân
* Đăng ký, đăng nhập bằng JWT Token.
* Quản lý hồ sơ cá nhân, đổi avatar.

---

## 🛠 Công nghệ sử dụng (Tech Stack)

### Frontend (iOS)
* **Ngôn ngữ:** Swift 5+
* **Framework:** UIKit (MVVM Architecture)
* **Yêu cầu OS:** iOS 18.0 trở lên
* **Công cụ:** Xcode

### Backend (Máy chủ)
* **Ngôn ngữ:** Python 3.11+
* **Framework:** FastAPI (Asynchronous)
* **Database:** PostgreSQL + SQLAlchemy (ORM) + Alembic (Migrations)
* **Kết nối:** RESTful APIs & WebSockets

---

## 🚀 Hướng dẫn cài đặt (Setup Guide)

### 1. Khởi chạy Backend (Máy chủ)
Yêu cầu đã cài đặt: `Python`, `PostgreSQL`.

```bash
# Di chuyển vào thư mục backend
cd backend

# Cài đặt môi trường và thư viện
python -m venv venv
source venv/bin/activate  # (hoặc venv\Scripts\activate trên Windows)
pip install -r requirements.txt

# Cấu hình biến môi trường (Database)
cp .env.example .env
# Chỉnh sửa file .env với thông tin PostgreSQL của bạn

# Chạy database migrations
alembic upgrade head

# Khởi động server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Khởi chạy Frontend (iOS)
Yêu cầu đã cài đặt: `Xcode` (chạy macOS).

1. Mở file `BoxChat.xcodeproj` trong thư mục `frontend/BoxChat/` bằng Xcode.
2. Kiểm tra file `Constants.swift` (hoặc `NetworkManager`) để đảm bảo địa chỉ IP backend (BASE_URL) đang trỏ đúng về `http://<IP-Máy-Của-Bạn>:8000`.
3. Chọn thiết bị giả lập (Simulator) hoặc iPhone thật.
4. Bấm **Run (Cmd + R)** để 빌드 và chạy ứng dụng.

---

## 👨‍💻 Tác giả
* **Minhhai3105** - Nâng cấp toàn diện UI/UX (Design System), Feed Comments, Fix lỗi Voice/WebSocket.
* **HungPig / ThanhHung / TuanNguyen** - Khởi tạo nền tảng Repo, Database, Auth & Chat cơ bản.

---
*Dự án được xây dựng và phát triển liên tục.*
