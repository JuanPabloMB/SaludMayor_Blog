"""Configuracion unica de SaludMayor almacenada en MySQL."""
from fastapi import HTTPException
from sqlalchemy import select
from models import Configuracion
from core.security import utc_now


def obtener(db, bloquear=False):
    stmt = select(Configuracion).where(Configuracion.id_configuracion == 1)
    if bloquear:
        stmt = stmt.with_for_update()
    conf = db.scalar(stmt)
    if conf is None:
        raise HTTPException(404, 'Configuracion no encontrada')
    return conf


def guardar(db, conf, usuario):
    conf.id_usuario = usuario.id_usuario
    conf.fecha_actualizacion = utc_now()
    db.commit()
    db.refresh(conf)
    return conf
