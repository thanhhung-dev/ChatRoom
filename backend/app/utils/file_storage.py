import uuid
from pathlib import Path

from fastapi import HTTPException, UploadFile, status

from app.config import settings

ALLOWED_EXTENSIONS = {
    # images
    ".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg", ".heic", ".heif",
    # videos
    ".mp4", ".mov", ".m4v", ".webm",
    # audio
    ".m4a", ".aac", ".mp3", ".wav",
    # documents
    ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
    ".txt", ".csv", ".rtf", ".md", ".json", ".xml", ".html",
    ".zip", ".rar", ".7z",
    # Apple/iWork documents
    ".pages", ".numbers", ".key",
}

BASE_UPLOAD_DIR = Path(settings.upload_dir)


def save_file(file: UploadFile, room_id: int) -> tuple[str, str]:
    _validate_file_type(file.filename)
    _validate_file_size(file)

    ext = Path(file.filename).suffix.lower()
    unique_name = f"{uuid.uuid4()}{ext}"
    room_dir = BASE_UPLOAD_DIR / str(room_id)
    room_dir.mkdir(parents=True, exist_ok=True)
    file_path = room_dir / unique_name

    with open(file_path, "wb") as f:
        f.write(file.file.read())

    file_url = f"/uploads/{room_id}/{unique_name}"
    return file_url, file.filename


def get_file_path(file_url: str) -> Path:
    parts = file_url.strip("/").split("/")
    if len(parts) != 3 or parts[0] != "uploads":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file URL",
        )
    return BASE_UPLOAD_DIR / parts[1] / parts[2]


def _validate_file_type(filename: str) -> None:
    ext = Path(filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File type '{ext}' not allowed",
        )


def _validate_file_size(file: UploadFile) -> None:
    max_bytes = settings.max_file_size_mb * 1024 * 1024
    file.file.seek(0, 2)
    size = file.file.tell()
    file.file.seek(0)
    if size > max_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File exceeds {settings.max_file_size_mb}MB limit",
        )
