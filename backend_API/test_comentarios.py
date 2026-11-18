"""Pruebas HTTP y de cascada en MySQL; solo borra la publicacion de prueba."""
from uuid import uuid4
from sqlalchemy import select
from database import SessionLocal
from models import Comentario
from test_usuarios import call
from test_blog import login


def main():
    admin = login('administrador')
    normal = None
    ruta = None
    try:
        a = call('/auth/me', token=admin)
        assert a['rol'] == 'administrador'
        normal = login('usuario normal')
        u = call('/auth/me', token=normal)
        assert u['rol'] == 'usuario'
        cats = call('/categorias', token=admin)
        assert cats
        post = call('/blog', 'POST', dict(id_categoria=cats[0]['id_categoria'],
                    titulo='Prueba comentarios ' + uuid4().hex,
                    descripcion='Descripcion de prueba', contenido='Contenido de prueba'), admin, 201)
        id_blog = post['id_blog']
        ruta = f'/blog/{id_blog}'
        endpoint = ruta + '/comentarios'
        datos = {'comentario': '  Comentario de prueba con acento: salud y prevención  '}
        call(endpoint, expected=401)
        call(endpoint, 'POST', datos, expected=401)
        assert call(endpoint, token=normal) == []
        for invalido in ({'comentario':'   '}, {'comentario':''}, {'comentario':'x'*4001},
                         {'comentario':None}, dict(datos,id_usuario=a['id_usuario']),
                         dict(datos,id_blog=id_blog), dict(datos,estado=False)):
            call(endpoint, 'POST', invalido, normal, 422)
        primero = call(endpoint, 'POST', datos, normal, 201)
        assert primero['comentario'] == datos['comentario'].strip()
        assert primero['id_usuario'] == u['id_usuario'] and primero['id_blog'] == id_blog
        assert primero['usuario']['id_usuario'] == u['id_usuario'] and primero['fecha_comentario']
        assert not ({'correo','contrasena','rol','foto_perfil'} & primero['usuario'].keys())
        segundo = call(endpoint, 'POST', {'comentario':'Respuesta del administrador'}, admin, 201)
        assert segundo['id_usuario'] == a['id_usuario']
        lista = call(endpoint, token=normal)
        assert [x['id_comentario'] for x in lista] == [primero['id_comentario'], segundo['id_comentario']]
        assert call(endpoint, token=admin) == lista
        assert call(endpoint+'?offset=1&limite=1', token=normal) == [segundo]
        call(endpoint+'?limite=101', token=normal, expected=422)
        call(endpoint+'?offset=-1', token=normal, expected=422)
        with SessionLocal() as db:
            assert len(db.scalars(select(Comentario.id_comentario).where(Comentario.id_blog==id_blog)).all()) == 2
        print('OK comentarios persistidos en MySQL')
        call(ruta, 'DELETE', token=admin)
        ruta = None
        call(endpoint, token=normal, expected=404)
        call(endpoint, 'POST', datos, normal, 404)
        with SessionLocal() as db:
            assert not db.scalars(select(Comentario.id_comentario).where(Comentario.id_blog==id_blog)).all()
        print('OK eliminacion en cascada en MySQL')
        print('PRUEBAS DE COMENTARIOS EXITOSAS')
    finally:
        if ruta:
            try: call(ruta, 'DELETE', token=admin)
            except Exception: print('Revisar publicacion de prueba:', ruta)
        for token in (normal, admin):
            if token:
                try: call('/auth/logout','POST',token=token)
                except Exception: print('No se pudo cerrar una sesion de prueba')

if __name__ == '__main__':
    main()
