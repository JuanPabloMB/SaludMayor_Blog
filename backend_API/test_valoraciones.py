"""Pruebas HTTP y persistencia; usa solo una publicacion temporal."""
from uuid import uuid4
from sqlalchemy import select
from database import SessionLocal
from models import Valoracion
from test_usuarios import call
from test_blog import login


def main():
    admin = login('administrador')
    normal = ruta = None
    try:
        a = call('/auth/me', token=admin)
        assert a['rol'] == 'administrador'
        normal = login('usuario normal')
        u = call('/auth/me', token=normal)
        assert u['rol'] == 'usuario'
        cats = call('/categorias', token=admin)
        post = call('/blog', 'POST', dict(id_categoria=cats[0]['id_categoria'],
                    titulo='Prueba valoraciones '+uuid4().hex,
                    descripcion='Descripcion de prueba', contenido='Contenido de prueba'), admin, 201)
        id_blog = post['id_blog']
        ruta = f'/blog/{id_blog}'
        ep = ruta+'/valoraciones'
        call(ep, expected=401)
        call(ep, 'PUT', {'puntuacion':5}, expected=401)
        assert call(ep, token=normal) == dict(id_blog=id_blog,promedio=None,total=0,mi_puntuacion=None)
        for datos in ({'puntuacion':p} for p in (0,6,-1,2.5,'5',True,None)):
            call(ep,'PUT',datos,normal,422)
        for datos in ({}, {'puntuacion':5,'id_usuario':a['id_usuario']}, {'puntuacion':5,'id_blog':id_blog}):
            call(ep,'PUT',datos,normal,422)
        assert call(ep,'PUT',{'puntuacion':5},normal) == dict(id_blog=id_blog,promedio=5,total=1,mi_puntuacion=5)
        with SessionLocal() as db:
            original = db.scalar(select(Valoracion.id_valoracion).where(Valoracion.id_blog==id_blog))
            assert original is not None
        assert call(ep,token=admin)['mi_puntuacion'] is None
        assert call(ep,'PUT',{'puntuacion':3},admin) == dict(id_blog=id_blog,promedio=4,total=2,mi_puntuacion=3)
        esperado = dict(id_blog=id_blog,promedio=3.5,total=2,mi_puntuacion=4)
        assert call(ep,'PUT',{'puntuacion':4},normal) == esperado
        assert call(ep,'PUT',{'puntuacion':4},normal) == esperado
        assert call(ep,token=normal) == esperado
        assert call(ep,token=admin) == dict(esperado,mi_puntuacion=3)
        with SessionLocal() as db:
            filas = db.scalars(select(Valoracion).where(Valoracion.id_blog==id_blog)).all()
            assert len(filas)==2
            assert {v.id_usuario:v.puntuacion for v in filas} == {u['id_usuario']:4,a['id_usuario']:3}
            assert next(v.id_valoracion for v in filas if v.id_usuario==u['id_usuario']) == original
        print('OK valoraciones persistidas sin duplicados en MySQL')
        call(ruta,'DELETE',token=admin)
        ruta = None
        call(ep,token=normal,expected=404)
        call(ep,'PUT',{'puntuacion':5},normal,404)
        with SessionLocal() as db:
            assert not db.scalars(select(Valoracion.id_valoracion).where(Valoracion.id_blog==id_blog)).all()
        print('OK eliminacion en cascada en MySQL')
        print('PRUEBAS DE VALORACIONES EXITOSAS')
    finally:
        if ruta:
            try: call(ruta,'DELETE',token=admin)
            except Exception: print('Revisar publicacion de prueba:',ruta)
        for token in (normal,admin):
            if token:
                try: call('/auth/logout','POST',token=token)
                except Exception: print('No se pudo cerrar una sesion de prueba')


if __name__ == '__main__':
    main()
