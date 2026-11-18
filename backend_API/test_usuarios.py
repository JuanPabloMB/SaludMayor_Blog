"""Pruebas HTTP locales. Crea una cuenta de prueba persistente."""
import json
from io import BytesIO
from uuid import uuid4
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from PIL import Image

BASE = 'http://localhost:8000'

def call(path, method='GET', data=None, token=None, expected=200, raw=None, content_type='application/json'):
    headers = {'Content-Type': content_type}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    body = raw if raw is not None else (json.dumps(data).encode() if data is not None else None)
    try:
        response = urlopen(Request(BASE+path, data=body, headers=headers, method=method), timeout=30)
    except HTTPError as exc:
        response = exc
    with response:
        status = response.code
        result = response.read()
        mime = response.headers.get_content_type()
    assert status == expected, f'{method} {path}: esperado {expected}, obtenido {status}'
    print(f'OK {method} {path}: {status}')
    return json.loads(result) if mime == 'application/json' else result

def main():
    correo = f'prueba-{uuid4().hex[:12]}@example.com'
    # example.com puede ser aceptado por EmailStr; usar dominio publico convencional.
    correo = correo.replace('@example.com', '@gmail.com')
    clave = uuid4().hex + '!Aa'
    nueva = uuid4().hex + '!Bb'
    datos = dict(nombre='Prueba', apellido_paterno='Integracion', correo=correo, contrasena=clave)
    call('/usuarios/me', expected=401)
    call('/usuarios/registro','POST',dict(datos, rol='administrador'),expected=422)
    cuenta = call('/usuarios/registro','POST',datos,expected=201)
    assert cuenta['rol']=='usuario' and 'contrasena' not in cuenta
    call('/usuarios/registro','POST',datos,expected=409)
    def login(password, expected=200):
        return call('/auth/token','POST',dict(correo=correo,contrasena=password),expected=expected)
    token = login(clave)['access_token']
    otro = login(clave)['access_token']
    assert call('/usuarios/me',token=token)['correo']==correo
    call('/usuarios/me','PATCH',{'rol':'administrador'},token,422)
    assert call('/usuarios/me','PATCH',{'nombre':'Perfil actualizado'},token)['nombre']=='Perfil actualizado'
    usuarios = call('/usuarios',token=token)
    assert all('correo' not in u and 'contrasena' not in u and u['id_usuario']!=cuenta['id_usuario'] for u in usuarios)
    ruta = f"/usuarios/{cuenta['id_usuario']}/foto"
    call(ruta,token=token,expected=404)
    buf = BytesIO(); Image.new('RGB',(12,12),'blue').save(buf,format='PNG'); png=buf.getvalue()
    boundary = uuid4().hex
    def upload(content, expected):
        raw = (f'--{boundary}\r\nContent-Disposition: form-data; name="archivo"; filename="foto.png"\r\nContent-Type: image/png\r\n\r\n'.encode()+content+f'\r\n--{boundary}--\r\n'.encode())
        return call('/usuarios/me/foto','PUT',token=token,expected=expected,raw=raw,content_type=f'multipart/form-data; boundary={boundary}')
    upload(b'no es una imagen',422)
    upload(png,200)
    assert call(ruta,token=token)==png
    call('/usuarios/me/foto','DELETE',token=token)
    call(ruta,token=token,expected=404)
    call('/usuarios/me/contrasena','PUT',dict(contrasena_actual='incorrecta',contrasena_nueva=nueva),token,400)
    call('/usuarios/me/contrasena','PUT',dict(contrasena_actual=clave,contrasena_nueva=nueva),token)
    call('/auth/me',token=token,expected=401)
    call('/auth/me',token=otro,expected=401)
    login(clave,401)
    token=login(nueva)['access_token']
    call('/auth/logout','POST',token=token)
    print('Cuenta de prueba conservada:',correo)
    print('PRUEBAS DE USUARIOS EXITOSAS')

if __name__=='__main__':
    main()
