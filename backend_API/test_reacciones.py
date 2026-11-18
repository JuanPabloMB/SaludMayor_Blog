"""Pruebas HTTP y MySQL con una publicacion temporal."""
from uuid import uuid4
from sqlalchemy import select
from database import SessionLocal
from models import Reaccion, Comentario
from test_usuarios import call
from test_blog import login


def verificar(res, propia, total):
    assert res['mi_reaccion'] == propia, res
    assert sum(r['total'] for r in res['resultados']) == total, res


def main():
    admin = login('administrador')
    normal = ruta = None
    try:
        a = call('/auth/me', token=admin)
        assert a['rol'] == 'administrador'
        normal = login('usuario normal')
        u = call('/auth/me', token=normal)
        assert u['rol'] == 'usuario'
        call('/tipos-reaccion', expected=401)
        tipos = call('/tipos-reaccion', token=normal)
        assert len(tipos) >= 2 and all(t['estado'] for t in tipos)
        t1,t2 = [t['id_tipo_reaccion'] for t in tipos[:2]]
        cats = call('/categorias', token=admin)
        post = call('/blog','POST',dict(id_categoria=cats[0]['id_categoria'],
            titulo='Prueba reacciones '+uuid4().hex, descripcion='Prueba', contenido='Prueba'),admin,201)
        ruta = f"/blog/{post['id_blog']}"
        c = call(ruta+'/comentarios','POST',{'comentario':'Comentario temporal'},normal,201)
        cid = c['id_comentario']
        ep = f'/comentarios/{cid}/reacciones'
        call(ep,expected=401)
        call(ep,'PUT',{'id_tipo_reaccion':t1},expected=401)
        call(ep,'DELETE',expected=401)
        verificar(call(ep,token=normal),None,0)
        for datos in ({}, {'id_tipo_reaccion':0}, {'id_tipo_reaccion':4294967295},
                      {'id_tipo_reaccion':t1,'id_usuario':a['id_usuario']}):
            call(ep,'PUT',datos,normal,422)
        verificar(call(ep,'PUT',{'id_tipo_reaccion':t1},normal),t1,1)
        with SessionLocal() as db:
            original = db.scalar(select(Reaccion.id_reaccion).where(Reaccion.id_comentario==cid))
            assert original is not None
        verificar(call(ep,'PUT',{'id_tipo_reaccion':t1},admin),t1,2)
        res = call(ep,'PUT',{'id_tipo_reaccion':t2},normal)
        verificar(res,t2,2)
        assert {r['tipo_reaccion']['id_tipo_reaccion']:r['total'] for r in res['resultados']} == {t['id_tipo_reaccion']:int(t['id_tipo_reaccion'] in (t1,t2)) for t in tipos}
        verificar(call(ep,'PUT',{'id_tipo_reaccion':t2},normal),t2,2)
        with SessionLocal() as db:
            filas = db.scalars(select(Reaccion).where(Reaccion.id_comentario==cid)).all()
            assert len(filas)==2
            assert {r.id_usuario:r.id_tipo_reaccion for r in filas}=={u['id_usuario']:t2,a['id_usuario']:t1}
            assert next(r.id_reaccion for r in filas if r.id_usuario==u['id_usuario'])==original
        print('OK reacciones persistidas sin duplicados en MySQL')
        verificar(call(ep,'DELETE',token=normal),None,1)
        verificar(call(ep,'DELETE',token=normal),None,1)
        verificar(call(ep,token=admin),t1,1)
        verificar(call(ep,'PUT',{'id_tipo_reaccion':t2},normal),t2,2)
        call(ruta,'DELETE',token=admin)
        ruta=None
        call(ep,token=normal,expected=404)
        call(ep,'PUT',{'id_tipo_reaccion':t1},normal,404)
        call(ep,'DELETE',token=normal,expected=404)
        with SessionLocal() as db:
            assert db.get(Comentario,cid) is None
            assert not db.scalars(select(Reaccion.id_reaccion).where(Reaccion.id_comentario==cid)).all()
        print('OK eliminacion en cascada en MySQL')
        print('PRUEBAS DE REACCIONES EXITOSAS')
    finally:
        if ruta:
            try: call(ruta,'DELETE',token=admin)
            except Exception: print('Revisar publicacion temporal:',ruta)
        for token in (normal,admin):
            if token:
                try: call('/auth/logout','POST',token=token)
                except Exception: print('No se pudo cerrar una sesion')


if __name__ == '__main__':
    main()
