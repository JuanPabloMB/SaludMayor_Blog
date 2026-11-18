
"""Gestion de comentarios de publicaciones."""

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import joinedload

from models import Comentario
from core.security import utc_now
from services.blog_service import obtener


def listar(db, id_blog, offset, limite):
    """Obtiene los comentarios activos de una publicacion."""

    obtener(db, id_blog)

    stmt = (
        select(Comentario)
        .options(joinedload(Comentario.usuario))
        .where(
            Comentario.id_blog == id_blog,
            Comentario.estado.is_(True)
        )
        .order_by(
            Comentario.fecha_comentario.asc(),
            Comentario.id_comentario.asc()
        )
        .offset(offset)
        .limit(limite)
    )

    return db.scalars(stmt).all()


def crear(db, id_blog, datos, usuario):
    """Registra un comentario asociado al usuario autenticado."""

    # Bloquea la publicacion mientras se registra el comentario.
    obtener(db, id_blog, bloquear=True)

    comentario = Comentario(
        id_blog=id_blog,
        id_usuario=usuario.id_usuario,
        comentario=datos.comentario,
        fecha_comentario=utc_now(),
        estado=True
    )

    db.add(comentario)
    db.commit()
    db.refresh(comentario)

    return comentario


def eliminar(db, id_blog, id_comentario, usuario):
    """
    Realiza la eliminacion logica de un comentario.

    El propietario puede eliminar su propio comentario.
    El administrador puede eliminar cualquier comentario.
    """

    # Busca y bloquea el comentario para evitar modificaciones
    # simultaneas durante la validacion.
    stmt = (
        select(Comentario)
        .where(
            Comentario.id_comentario == id_comentario,
            Comentario.id_blog == id_blog,
            Comentario.estado.is_(True)
        )
        .with_for_update()
    )

    comentario = db.scalar(stmt)

    if comentario is None:
        raise HTTPException(
            status_code=404,
            detail="Comentario no encontrado"
        )

    # Comprueba los permisos del usuario autenticado.
    es_administrador = usuario.rol == "administrador"
    es_propietario = comentario.id_usuario == usuario.id_usuario

    if not es_administrador and not es_propietario:
        raise HTTPException(
            status_code=403,
            detail="No tienes permiso para eliminar este comentario"
        )

    # Eliminacion logica: conserva el registro en MySQL.
    comentario.estado = False

    db.commit()
