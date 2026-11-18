"""Prueba de lectura y correspondencia de los modelos con MySQL."""
from sqlalchemy import inspect, select, func
from sqlalchemy.orm import configure_mappers, joinedload
from database import Base, SessionLocal, engine
from models import (Usuario, Categoria, Blog, Comentario, Valoracion,
                    TipoReaccion, Reaccion, Mensaje, Configuracion, Sesion)


def main():
    configure_mappers()
    inspector = inspect(engine)
    assert set(Base.metadata.tables) == set(inspector.get_table_names())
    for tabla in Base.metadata.sorted_tables:
        columnas = {c['name']: c for c in inspector.get_columns(tabla.name)}
        assert set(columnas) == set(tabla.columns.keys()), tabla.name
        for c in tabla.columns:
            assert c.nullable == columnas[c.name]['nullable'], (tabla.name, c.name)
        assert set(inspector.get_pk_constraint(tabla.name)['constrained_columns']) == {c.name for c in tabla.primary_key}
        reales = {(tuple(f['constrained_columns']), f['referred_table'], tuple(f['referred_columns'])) for f in inspector.get_foreign_keys(tabla.name)}
        esperadas = {(tuple(e.parent.name for e in f.elements), f.referred_table.name, tuple(e.column.name for e in f.elements)) for f in tabla.foreign_key_constraints}
        assert reales == esperadas, tabla.name
        print(f'Estructura OK: {tabla.name}')
    with SessionLocal() as db:
        for modelo in (Usuario, Categoria, Blog, Comentario, Valoracion, TipoReaccion, Reaccion, Mensaje, Configuracion, Sesion):
            total = db.scalar(select(func.count()).select_from(modelo))
            print(f'{modelo.__name__}: {total} registros')
        print('\nPUBLICACIONES Y RELACIONES:')
        for blog in db.scalars(select(Blog).options(joinedload(Blog.autor), joinedload(Blog.categoria)).order_by(Blog.id_blog)):
            assert blog.autor.rol == 'administrador'
            print(f'{blog.titulo} | {blog.autor.nombre} | {blog.categoria.nombre}')
        print('\nCOMENTARIOS Y REACCIONES:')
        for comentario in db.scalars(select(Comentario).order_by(Comentario.id_comentario)):
            print(f'{comentario.usuario.nombre}: {comentario.comentario} | ' + ' '.join(r.tipo_reaccion.emoji for r in comentario.reacciones))
        print('\nMENSAJES:')
        for mensaje in db.scalars(select(Mensaje).order_by(Mensaje.id_mensaje)):
            print(f'{mensaje.emisor.nombre} -> {mensaje.receptor.nombre}')
        print('\nIMAGENES:')
        blog = db.get(Blog, 1)
        config = db.get(Configuracion, 1)
        assert blog and blog.imagen and config and config.logotipo
        print(f'Publicacion: {len(blog.imagen)} bytes | {blog.tipo_imagen}')
        print(f'Logotipo: {len(config.logotipo)} bytes | {config.tipo_imagen}')
    print('\nPRUEBAS DE MODELOS EXITOSAS')


if __name__ == '__main__':
    try:
        main()
    finally:
        engine.dispose()
