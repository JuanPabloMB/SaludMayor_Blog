"""Estadísticas agregadas del blog; no consulta mensajes privados."""
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from models import Usuario, Categoria, Blog, Comentario, Valoracion, Reaccion


def resumen(db: Session) -> dict:
    def contar(modelo, *condiciones):
        return db.scalar(select(func.count()).select_from(modelo).where(*condiciones)) or 0

    categorias = db.execute(
        select(Categoria.id_categoria, Categoria.nombre, Categoria.estado,
               func.count(Blog.id_blog))
        .outerjoin(Blog, Blog.id_categoria == Categoria.id_categoria)
        .group_by(Categoria.id_categoria, Categoria.nombre, Categoria.estado)
        .order_by(Categoria.nombre)
    ).all()
    recientes = db.execute(
        select(Blog.id_blog, Blog.titulo, Categoria.nombre, Blog.fecha_publicacion)
        .join(Categoria, Blog.id_categoria == Categoria.id_categoria)
        .order_by(Blog.fecha_publicacion.desc(), Blog.id_blog.desc()).limit(5)
    ).all()
    return {
        'usuarios_activos': contar(Usuario, Usuario.estado.is_(True)),
        'usuarios_inactivos': contar(Usuario, Usuario.estado.is_(False)),
        'publicaciones': sum(fila[3] for fila in categorias),
        'categorias_activas': sum(1 for fila in categorias if fila[2]),
        'categorias_inactivas': sum(1 for fila in categorias if not fila[2]),
        'comentarios': contar(Comentario, Comentario.estado.is_(True)),
        'valoraciones': contar(Valoracion),
        'reacciones': contar(Reaccion, Reaccion.id_comentario.in_(
            select(Comentario.id_comentario).where(Comentario.estado.is_(True)))),
        'distribucion': [dict(id_categoria=i, nombre=n, estado=e, total=t)
                         for i, n, e, t in categorias],
        'recientes': [dict(id_blog=i, titulo=t, categoria=c, fecha_publicacion=f)
                      for i, t, c, f in recientes],
    }
