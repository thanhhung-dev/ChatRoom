from fastapi import FastAPI

from app.api.router import api_router
from app.ws.handle import router as ws_router

description = """
**ChatRoom API** — backend cho ứng dụng chat thời gian thực.

Cung cấp các nhóm tính năng:

* **auth** — đăng ký, đăng nhập, refresh & logout bằng JWT.
* **users** — quản lý hồ sơ người dùng và đổi mật khẩu.
* **rooms** — tạo/tham gia/rời phòng chat, quản lý thành viên, mã mời.
* **messages** — lấy lịch sử tin nhắn (phân trang) và upload file.
* **websocket** — kênh thời gian thực tại `/ws?token=<access_token>` cho
  tin nhắn, typing indicator, trạng thái online và đồng bộ tin nhắn.

### Xác thực
Hầu hết endpoint yêu cầu header `Authorization: Bearer <access_token>`.
Lấy token qua `POST /api/v1/auth/login`.
"""

tags_metadata = [
    {"name": "auth", "description": "Đăng ký, đăng nhập và quản lý token JWT."},
    {"name": "users", "description": "Hồ sơ người dùng và đổi mật khẩu."},
    {"name": "rooms", "description": "Tạo, tham gia, rời và quản lý phòng chat."},
    {"name": "messages", "description": "Lịch sử tin nhắn và upload file."},
]

app = FastAPI(
    title="ChatRoom API",
    description=description,
    version="1.0.0",
    openapi_tags=tags_metadata,
)
app.include_router(api_router)
app.include_router(ws_router)


@app.get("/health", tags=["health"], summary="Health check")
async def health() -> dict:
    """Kiểm tra server còn sống. Trả về `{\"status\": \"ok\"}`."""
    return {"status": "ok"}
