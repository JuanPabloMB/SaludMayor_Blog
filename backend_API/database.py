
"""
Archivo: database.py

Descripcion:
Establece la conexion con la base de datos MySQL
mediante SQLAlchemy y administra las sesiones
utilizadas por el backend de SaludMayor Blog.

Autor:
Equipo SaludMayor.
"""

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.orm import declarative_base, sessionmaker, Session

from core.config import settings


# Configuracion de la conexion
DATABASE_URL = URL.create(
    drivername="mysql+pymysql",
    username=settings.DB_USER,
    password=settings.DB_PASSWORD,
    host=settings.DB_HOST,
    port=settings.DB_PORT,
    database=settings.DB_NAME,
    query={
        "charset": "utf8mb4"
    }
)


# Motor de conexion
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=1800,
    echo=False
)


# Fabrica de sesiones
SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False
)


# Clase base para los modelos
Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    """
    Proporciona una sesion de base de datos
    y garantiza su cierre al finalizar.
    """

    db = SessionLocal()

    try:
        yield db

    except Exception:
        db.rollback()
        raise

    finally:
        db.close()
