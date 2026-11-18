"""Operaciones de publicaciones y validacion de categorias."""
from fastapi import HTTPException
from sqlalchemy import select, or_
from sqlalchemy.orm import joinedload, defer
from models import Blog, Categoria
from core.security import utc_now


def obtener(db, id_blog, bloquear=False):
    stmt = select(Blog).where(Blog.id_blog == id_blog)
    if bloquear:
        stmt = stmt.with_for_update()
    blog = db.scalar(stmt)
    if blog is None:
        raise HTTPException(404, 'Publicacion no encontrada')
    return blog


def categoria_activa(db, id_categoria):
    categoria = db.get(Categoria, id_categoria)
    if categoria is None or not categoria.estado:
        raise HTTPException(422, 'Categoria inexistente o inactiva')


def listar(db, buscar, id_categoria, offset, limite):
    stmt = select(Blog).options(defer(Blog.contenido), joinedload(Blog.autor), joinedload(Blog.categoria))
    if buscar:
        stmt = stmt.where(or_(Blog.titulo.contains(buscar, autoescape=True), Blog.descripcion.contains(buscar, autoescape=True)))
    if id_categoria is not None:
        stmt = stmt.where(Blog.id_categoria == id_categoria)
    return db.scalars(stmt.order_by(Blog.fecha_publicacion.desc(), Blog.id_blog.desc()).offset(offset).limit(limite)).all()


def guardar(db, blog):
    db.add(blog)
    db.commit()
    db.refresh(blog)
    return blog


def crear(db, datos, usuario):
    categoria_activa(db, datos.id_categoria)
    return guardar(db, Blog(**datos.model_dump(), id_usuario=usuario.id_usuario, fecha_publicacion=utc_now()))


def actualizar(db, id_blog, datos):
    blog = obtener(db, id_blog, bloquear=True)
    cambios = datos.model_dump(exclude_unset=True)
    if 'id_categoria' in cambios:
        categoria_activa(db, cambios['id_categoria'])
    for campo, valor in cambios.items():
        setattr(blog, campo, valor)
    blog.fecha_actualizacion = utc_now()
    return guardar(db, blog)


def eliminar(db, id_blog):
    db.delete(obtener(db, id_blog, bloquear=True))
    db.commit()
