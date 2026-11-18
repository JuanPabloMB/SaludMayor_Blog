"""Valoraciones unicas por usuario y publicacion en MySQL."""
from sqlalchemy import select, func, case
from sqlalchemy.dialects.mysql import insert
from models import Valoracion
from core.security import utc_now
from services.blog_service import obtener


def resumen(db, id_blog, id_usuario):
    obtener(db, id_blog)
    promedio, total, propia = db.execute(select(
        func.avg(Valoracion.puntuacion),
        func.count(Valoracion.id_valoracion),
        func.max(case((Valoracion.id_usuario == id_usuario, Valoracion.puntuacion), else_=None))
    ).where(Valoracion.id_blog == id_blog)).one()
    return dict(id_blog=id_blog, promedio=float(promedio) if promedio is not None else None,
                total=total, mi_puntuacion=propia)


def guardar(db, id_blog, datos, usuario):
    id_usuario = usuario.id_usuario
    obtener(db, id_blog, bloquear=True)
    fecha = utc_now()
    stmt = insert(Valoracion).values(id_blog=id_blog, id_usuario=id_usuario,
                                    puntuacion=datos.puntuacion, fecha_valoracion=fecha)
    stmt = stmt.on_duplicate_key_update(puntuacion=stmt.inserted.puntuacion,
                                        fecha_valoracion=stmt.inserted.fecha_valoracion)
    db.execute(stmt)
    db.commit()
    return resumen(db, id_blog, id_usuario)
