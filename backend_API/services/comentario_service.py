"""Creacion y lectura de comentarios de publicaciones privadas."""
from sqlalchemy import select
from sqlalchemy.orm import joinedload
from models import Comentario
from core.security import utc_now
from services.blog_service import obtener


def listar(db, id_blog, offset, limite):
    obtener(db, id_blog)
    stmt = (select(Comentario).options(joinedload(Comentario.usuario))
            .where(Comentario.id_blog == id_blog, Comentario.estado.is_(True))
            .order_by(Comentario.fecha_comentario.asc(), Comentario.id_comentario.asc())
            .offset(offset).limit(limite))
    return db.scalars(stmt).all()


def crear(db, id_blog, datos, usuario):
    # Bloquea la publicacion hasta guardar para coordinar con su eliminacion.
    obtener(db, id_blog, bloquear=True)
    comentario = Comentario(id_blog=id_blog, id_usuario=usuario.id_usuario,
                            comentario=datos.comentario, fecha_comentario=utc_now(), estado=True)
    db.add(comentario)
    db.commit()
    db.refresh(comentario)
    return comentario
