"""Administracion del catalogo sin eliminacion fisica."""
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from models import Categoria


def listar(db, solo_activas=True):
    stmt = select(Categoria)
    if solo_activas:
        stmt = stmt.where(Categoria.estado.is_(True))
    return db.scalars(stmt.order_by(Categoria.nombre, Categoria.id_categoria)).all()


def obtener(db, identificador):
    categoria = db.scalar(select(Categoria).where(
        Categoria.id_categoria == identificador).with_for_update())
    if categoria is None:
        raise HTTPException(404, 'Categoria no encontrada')
    return categoria


def guardar(db, categoria):
    db.add(categoria)
    try:
        db.commit()
    except IntegrityError as error:
        db.rollback()
        if getattr(error.orig, 'args', (None,))[0] == 1062:
            raise HTTPException(409, 'Ya existe una categoria con ese nombre') from None
        raise
    db.refresh(categoria)
    return categoria


def crear(db, datos):
    return guardar(db, Categoria(**datos.model_dump(), estado=True))


def editar(db, identificador, datos):
    categoria = obtener(db, identificador)
    categoria.nombre = datos.nombre
    categoria.descripcion = datos.descripcion
    return guardar(db, categoria)


def cambiar_estado(db, identificador, estado):
    categoria = obtener(db, identificador)
    categoria.estado = estado
    return guardar(db, categoria)
