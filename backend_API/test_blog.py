"""Pruebas HTTP del CRUD. Crea y elimina solo una publicacion propia de prueba."""
from getpass import getpass
from io import BytesIO
from uuid import uuid4
from urllib.parse import urlencode
from PIL import Image
from test_usuarios import call


def login(etiqueta):
    correo = input(f'Correo {etiqueta}: ').strip()
    clave = getpass(f'Contrasena {etiqueta}: ')
    return call('/auth/token', 'POST', dict(correo=correo, contrasena=clave))['access_token']


def main():
    admin = login('administrador')
    normal = None
    ruta = None
    try:
        assert call('/auth/me', token=admin)['rol'] == 'administrador'
        normal = login('usuario normal')
        assert call('/auth/me', token=normal)['rol'] == 'usuario'
        call('/categorias', expected=401)
        call('/blog', expected=401)
        cats = call('/categorias', token=normal)
        assert cats and all(c['estado'] for c in cats)
        titulo = 'Prueba CRUD ' + uuid4().hex
        datos = dict(id_categoria=cats[0]['id_categoria'], titulo=titulo, descripcion='Descripcion de prueba', contenido='Contenido de prueba')
        call('/blog', 'POST', datos, normal, 403)
        call('/blog', 'POST', dict(datos, id_usuario=1), admin, 422)
        call('/blog', 'POST', dict(datos, titulo=' '), admin, 422)
        call('/blog', 'POST', dict(datos, id_categoria=0), admin, 422)
        creado = call('/blog', 'POST', datos, admin, 201)
        ruta = f"/blog/{creado['id_blog']}"
        assert creado['id_usuario'] == call('/auth/me', token=admin)['id_usuario']
        call(ruta, expected=401)
        assert call(ruta, token=normal)['contenido'] == datos['contenido']
        lista = call('/blog?' + urlencode(dict(buscar=titulo, id_categoria=datos['id_categoria'], limite=10)), token=normal)
        assert len(lista)==1 and lista[0]['id_blog']==creado['id_blog'] and 'contenido' not in lista[0] and 'imagen' not in lista[0]
        call(ruta, 'PATCH', {'titulo':'No autorizado'}, normal, 403)
        call(ruta, 'DELETE', token=normal, expected=403)
        call(ruta, 'PATCH', {'id_usuario':1}, admin, 422)
        editado = call(ruta, 'PATCH', {'titulo':titulo+' editado'}, admin)
        assert editado['titulo']==titulo+' editado' and editado['fecha_actualizacion'] is not None
        img = ruta+'/imagen'
        call(img, token=normal, expected=404)
        buf = BytesIO(); Image.new('RGB',(16,16),'blue').save(buf,format='PNG'); png=buf.getvalue()
        def upload(content, token, expected):
            boundary=uuid4().hex
            raw=(f'--{boundary}\r\nContent-Disposition: form-data; name="archivo"; filename="prueba.png"\r\nContent-Type: image/png\r\n\r\n'.encode()+content+f'\r\n--{boundary}--\r\n'.encode())
            return call(img,'PUT',token=token,expected=expected,raw=raw,content_type=f'multipart/form-data; boundary={boundary}')
        upload(png,normal,403)
        upload(b'invalida',admin,422)
        upload(b'x'*(5242881),admin,413)
        assert upload(png,admin,200)['tipo_imagen']=='image/png'
        call(img,expected=401)
        assert call(img,token=normal)==png
        call(img,'DELETE',token=normal,expected=403)
        assert call(img,'DELETE',token=admin)['tipo_imagen'] is None
        call(img,token=normal,expected=404)
        upload(png,admin,200)
        call(ruta,'DELETE',token=admin)
        eliminada=ruta; ruta=None
        call(eliminada,token=normal,expected=404)
        call(eliminada+'/imagen',token=normal,expected=404)
        print('PRUEBAS DE PUBLICACIONES EXITOSAS')
    finally:
        if ruta:
            try: call(ruta,'DELETE',token=admin)
            except Exception: print('Revisar publicacion de prueba:',ruta)
        for token in (normal,admin):
            if token:
                try: call('/auth/logout','POST',token=token)
                except Exception: print('No se pudo cerrar una sesion de prueba')

if __name__=='__main__':
    main()
