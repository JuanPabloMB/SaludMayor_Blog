"""Pruebas locales: restaura la configuracion original al terminar."""
from io import BytesIO
from uuid import uuid4
from PIL import Image
from database import SessionLocal
from models import Configuracion
from core.config import settings
from test_usuarios import call
from test_blog import login


def upload(token, contenido, expected=200, mime='image/png'):
    b = uuid4().hex
    raw = (f'--{b}\r\nContent-Disposition: form-data; name="archivo"; filename="logo.png"\r\nContent-Type: {mime}\r\n\r\n'.encode()
           + contenido + f'\r\n--{b}--\r\n'.encode())
    return call('/configuracion/logotipo', 'PUT', token=token, expected=expected,
                raw=raw, content_type=f'multipart/form-data; boundary={b}')


def main():
    admin = normal = None
    original = None
    modificado = False
    ruta = '/configuracion'
    logo = ruta + '/logotipo'
    try:
        admin = login('administrador')
        uid = call('/auth/me', token=admin)['id_usuario']
        assert call('/auth/me', token=admin)['rol'] == 'administrador'
        normal = login('usuario normal')
        assert call('/auth/me', token=normal)['rol'] == 'usuario'
        with SessionLocal() as db:
            conf = db.get(Configuracion, 1)
            assert conf is not None
            original = {k: getattr(conf, k) for k in ('nombre_app','logotipo','tipo_imagen','fecha_actualizacion','id_usuario')}
        resp = call(ruta)
        assert resp['nombre_app'] == original['nombre_app'] and 'logotipo' not in resp
        if original['logotipo'] is None:
            call(logo, expected=404)
        else:
            assert call(logo) == original['logotipo']
        datos = {'nombre_app': 'SaludMayor Prueba ' + uuid4().hex[:8]}
        call(ruta, 'PATCH', datos, expected=401)
        call(ruta, 'PATCH', datos, normal, 403)
        for invalido in (' ', '', 'x'*101):
            call(ruta, 'PATCH', {'nombre_app': invalido}, admin, 422)
        call(ruta, 'PATCH', dict(datos, id_usuario=uid), admin, 422)
        buf = BytesIO()
        Image.new('RGB', (16,16), 'green').save(buf, format='PNG')
        png = buf.getvalue()
        upload(None, png, 401)
        upload(normal, png, 403)
        call(logo, 'DELETE', expected=401)
        call(logo, 'DELETE', token=normal, expected=403)
        upload(admin, b'invalido', 422)
        upload(admin, png, 415, 'image/jpeg')
        upload(admin, b'x'*(settings.MAX_LOGO_IMAGE_SIZE+1), 413)
        modificado = True
        assert call(ruta, 'PATCH', datos, admin)['nombre_app'] == datos['nombre_app']
        assert call(ruta)['nombre_app'] == datos['nombre_app']
        assert upload(admin, png)['tipo_imagen'] == 'image/png'
        assert call(logo) == png
        with SessionLocal() as db:
            conf = db.get(Configuracion, 1)
            assert conf.nombre_app == datos['nombre_app'] and conf.logotipo == png
            assert conf.tipo_imagen == 'image/png' and conf.id_usuario == uid
        print('OK configuracion y logotipo persistidos en MySQL')
        assert call(logo, 'DELETE', token=admin)['tipo_imagen'] is None
        call(logo, expected=404)
        call(logo, 'DELETE', token=admin)
        print('PRUEBAS DE CONFIGURACION EXITOSAS')
    finally:
        try:
            if modificado and original is not None:
                with SessionLocal() as db:
                    conf = db.get(Configuracion, 1)
                    for k, v in original.items():
                        setattr(conf, k, v)
                    db.commit()
                print('OK configuracion original restaurada')
        finally:
            for token in (normal, admin):
                if token:
                    call('/auth/logout', 'POST', token=token)


if __name__ == '__main__':
    main()
