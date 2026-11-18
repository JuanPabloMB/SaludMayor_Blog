"""Reacciones a comentarios activos, con una seleccion por usuario."""
from fastapi import HTTPException
from sqlalchemy import select, delete
from sqlalchemy.dialects.mysql import insert
from models import Comentario, Reaccion, TipoReaccion
from core.security import utc_now


def tipos(db):
    return db.scalars(select(TipoReaccion).where(TipoReaccion.estado.is_(True))
                      .order_by(TipoReaccion.id_tipo_reaccion)).all()


def obtener(db, id_comentario, bloquear=False):
    stmt = select(Comentario.id_comentario).where(
        Comentario.id_comentario == id_comentario, Comentario.estado.is_(True))
    if bloquear:
        stmt = stmt.with_for_update()
    if db.scalar(stmt) is None:
        raise HTTPException(404, 'Comentario no encontrado')


def resumen(db, id_comentario, id_usuario):
    obtener(db, id_comentario)
    catalogo = tipos(db)
    filas = db.execute(select(Reaccion.id_tipo_reaccion, Reaccion.id_usuario)
                       .where(Reaccion.id_comentario == id_comentario)).all()
    conteos = {t.id_tipo_reaccion: 0 for t in catalogo}
    propia = None
    for tipo, usuario in filas:
        if tipo in conteos:
            conteos[tipo] += 1
            if usuario == id_usuario:
                propia = tipo
    return dict(id_comentario=id_comentario, mi_reaccion=propia,
                resultados=[dict(tipo_reaccion=t, total=conteos[t.id_tipo_reaccion]) for t in catalogo])


def guardar(db, id_comentario, datos, usuario):
    uid = usuario.id_usuario
    obtener(db, id_comentario, bloquear=True)
    tipo = db.scalar(select(TipoReaccion.id_tipo_reaccion).where(
        TipoReaccion.id_tipo_reaccion == datos.id_tipo_reaccion,
        TipoReaccion.estado.is_(True)).with_for_update())
    if tipo is None:
        raise HTTPException(422, 'Tipo de reaccion no disponible')
    stmt = insert(Reaccion).values(id_comentario=id_comentario, id_usuario=uid,
                                  id_tipo_reaccion=tipo, fecha_reaccion=utc_now())
    db.execute(stmt.on_duplicate_key_update(id_tipo_reaccion=stmt.inserted.id_tipo_reaccion,
                                           fecha_reaccion=stmt.inserted.fecha_reaccion))
    db.commit()
    return resumen(db, id_comentario, uid)


def eliminar(db, id_comentario, usuario):
    uid = usuario.id_usuario
    obtener(db, id_comentario, bloquear=True)
    db.execute(delete(Reaccion).where(Reaccion.id_comentario == id_comentario,
                                    Reaccion.id_usuario == uid))
    db.commit()
    return resumen(db, id_comentario, uid)
