
"""
Archivo: config.py

Descripcion:
Gestiona las variables de entorno y la configuracion
general del backend de SaludMayor Blog.

Autor:
Equipo SaludMayor.
"""

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


BASE_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    """Configuracion general de la aplicacion."""

    # Aplicacion
    APP_NAME: str = "SaludMayor Blog"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # Base de datos
    DB_HOST: str = "localhost"
    DB_PORT: int = Field(default=3306, ge=1, le=65535)
    DB_USER: str
    DB_PASSWORD: str = Field(min_length=1)
    DB_NAME: str = "saludmayor_blog"

    # Seguridad
    JWT_SECRET_KEY: str = Field(min_length=32)
    JWT_ALGORITHM: Literal["HS256"] = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(
        default=60,
        gt=0
    )

    ALLOWED_HOSTS: list[str] = ["localhost", "127.0.0.1", "10.0.2.2", "testserver"]
    AUTH_REQUESTS_PER_MINUTE: int = Field(default=20, ge=1, le=1000)
    COOKIE_SECURE: bool = False

    # Flutter Web
    CORS_ORIGINS: list[str] = [
        "http://localhost:8080"
    ]

    # Limites de imagenes
    MAX_POST_IMAGE_SIZE: int = Field(
        default=5242880,
        gt=0,
        le=5242880
    )

    MAX_PROFILE_IMAGE_SIZE: int = Field(
        default=2097152,
        gt=0,
        le=2097152
    )

    MAX_LOGO_IMAGE_SIZE: int = Field(
        default=2097152,
        gt=0,
        le=2097152
    )

    # Configuracion del archivo de entorno
    model_config = SettingsConfigDict(
        env_file=BASE_DIR / ".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
        hide_input_in_errors=True
    )


@lru_cache
def get_settings() -> Settings:
    """Carga y reutiliza la configuracion."""
    return Settings()


settings = get_settings()
