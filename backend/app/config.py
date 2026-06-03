from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, field_validator


class Settings(BaseSettings):
    database_url: str = Field(..., alias="DATABASE_URL")
    jwt_secret_key: str = Field(..., alias="JWT_SECRET_KEY")
    jwt_algorithm: str = Field("HS256", alias="JWT_ALGORITHM")
    access_token_expire_minutes: int = Field(
        15, alias="ACCESS_TOKEN_EXPIRE_MINUTES"
    )
    refresh_token_expire_days: int = Field(
        7, alias="REFRESH_TOKEN_EXPIRE_DAYS"
    )
    upload_dir: str = Field("./uploads", alias="UPLOAD_DIR")
    max_file_size_mb: int = Field(10, alias="MAX_FILE_SIZE_MB")
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )
    @field_validator("access_token_expire_minutes", "refresh_token_expire_days")
    def validate_positive(cls, v):
        if v <= 0:
            raise ValueError("Must be > 0")
        return v

    @field_validator("max_file_size_mb")
    def validate_file_size(cls, v):
        if v <= 0 or v > 100:
            raise ValueError("File size must be between 1 and 100 MB")
        return v
settings = Settings()