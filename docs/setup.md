# Hướng dẫn Setup — Backend ChatRoom

---

## Yêu cầu hệ thống

- Python 3.11+
- PostgreSQL 15+
- pip hoặc poetry

---

## Bước 1: Tạo virtual environment

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

## Bước 2: Cài dependencies

```bash
pip install -r requirements.txt

# Dev dependencies (tests)
pip install -r requirements-dev.txt
```

## Bước 3: Setup database

```bash
# Tạo database trong PostgreSQL
psql -U postgres
CREATE DATABASE chatroom;
\q
```

## Bước 4: Configure environment

```bash
# Copy và chỉnh sửa .env
cp .env.example .env

# Sửa các giá trị:
# DATABASE_URL — connection string tới PostgreSQL
# JWT_SECRET_KEY — random secret key (dùng: python -c "import secrets; print(secrets.token_urlsafe(32))")
```

## Bước 5: Chạy migrations

```bash
alembic upgrade head
```

## Bước 6: Chạy server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Server sẽ chạy tại:
- API: `http://localhost:8000`
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- WebSocket: `ws://localhost:8000/ws`

## Bước 7: Chạy tests

```bash
pytest -v
```

## Bước 8: Seed data (tùy chọn)

```bash
python scripts/seed.py
```

---

## Cấu trúc project sau khi setup

```
backend/
├── alembic/
├── alembic.ini
├── app/
│   ├── api/
│   ├── core/
│   ├── models/
│   ├── schemas/
│   ├── services/
│   ├── utils/
│   ├── ws/
│   ├── dependencies.py
│   └── main.py
├── scripts/
│   └── seed.py
├── tests/
├── uploads/
├── .env
├── .env.example
├── requirements.txt
├── requirements-dev.txt
└── README.md
```
