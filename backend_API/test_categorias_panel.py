"""Prueba permisos, catalogo, persistencia de publicaciones y resumen."""
from uuid import uuid4
from test_usuarios import call
from test_blog import login


def main():
    admin = login('administrador')
    normal = None
    cid = None
    post = None
    ruta = '/categorias/admin'
    datos = {'nombre':'Prueba categoria '+uuid4().hex, 'descripcion':'Temporal'}
    try:
        assert call('/auth/me', token=admin)['rol'] == 'administrador'
        normal = login('usuario normal')
        assert call('/auth/me', token=normal)['rol'] == 'usuario'
        for ep in (ruta, '/panel/resumen'):
            call(ep, expected=401)
            call(ep, token=normal, expected=403)
        call(ruta, 'POST', datos, normal, 403)
        call(ruta, 'POST', {'nombre':' '}, admin, 422)
        antes = call('/panel/resumen', token=admin)
        cat = call(ruta, 'POST', datos, admin, 201)
        cid = cat['id_categoria']
        ep = f'{ruta}/{cid}'
        assert cat['estado'] is True
        call(ruta, 'POST', datos, admin, 409)
        call(ep, 'PATCH', datos, normal, 403)
        assert call(ep, 'PATCH', {**datos,'descripcion':'Editada'}, admin)['descripcion']=='Editada'
        contenido = dict(id_categoria=cid, titulo='Prueba '+uuid4().hex, descripcion='Temporal', contenido='Temporal')
        post = call('/blog', 'POST', contenido, admin, 201)['id_blog']
        resumen = call('/panel/resumen', token=admin)
        assert resumen['publicaciones'] == antes['publicaciones']+1
        assert resumen['categorias_activas'] == antes['categorias_activas']+1
        assert sum(x['total'] for x in resumen['distribucion']) == resumen['publicaciones']
        assert any(x['id_categoria']==cid and x['total']==1 for x in resumen['distribucion'])
        assert len(resumen['recientes']) <= 5 and 'mensajes' not in resumen
        assert call(ep+'/estado','PATCH',{'estado':False},admin)['estado'] is False
        assert cid not in [x['id_categoria'] for x in call('/categorias',token=normal)]
        assert any(x['id_categoria']==cid and not x['estado'] for x in call(ruta,token=admin))
        call(f'/blog/{post}',token=normal)
        call('/blog','POST',contenido,admin,422)
        assert call(ep+'/estado','PATCH',{'estado':True},admin)['estado'] is True
        assert cid in [x['id_categoria'] for x in call('/categorias',token=normal)]
        print('CATEGORIAS Y PANEL EXITOSOS')
    finally:
        try:
            if post is not None:
                call(f'/blog/{post}','DELETE',token=admin)
        finally:
            try:
                if cid is not None:
                    call(f'{ruta}/{cid}/estado','PATCH',{'estado':False},admin)
                    print('Categoria temporal conservada inactiva:', cid)
            finally:
                for t in (normal,admin):
                    if t: call('/auth/logout','POST',token=t)


if __name__ == '__main__':
    main()
