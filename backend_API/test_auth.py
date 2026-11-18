"""Prueba integrada contra Uvicorn local; no imprime credenciales ni tokens."""
import json
from urllib.request import Request, build_opener, HTTPCookieProcessor
from urllib.error import HTTPError
from http.cookiejar import CookieJar
from getpass import getpass
from core.security import hash_password, verify_password, create_token, decode_token
import jwt

BASE = 'http://localhost:8000'
jar = CookieJar()
client = build_opener(HTTPCookieProcessor(jar))

def call(path, method='GET', data=None, headers=None, expected=200):
    h = {'Content-Type':'application/json', **(headers or {})}
    req = Request(BASE+path, data=json.dumps(data).encode() if data is not None else None,
                  headers=h, method=method)
    try:
        with client.open(req, timeout=15) as r:
            status, body = r.status, json.load(r)
    except HTTPError as e:
        status, body = e.code, json.load(e)
    assert status == expected, f'{path}: esperado {expected}, obtenido {status}'
    print(f'OK {method} {path}: {status}')
    return body

def main():
    h = hash_password('Prueba local segura')
    assert h.startswith('$argon2id$') and verify_password('Prueba local segura', h)
    assert not verify_password('incorrecta', h)
    token, *_ = create_token(1, 'bearer')
    assert decode_token(token, 'bearer')['sub'] == '1'
    try:
        decode_token(token + 'x', 'bearer')
        raise AssertionError('Token alterado aceptado')
    except jwt.InvalidTokenError:
        pass
    print('OK Argon2id y firma JWT')
    correo = input('Correo de cuenta de prueba: ').strip()
    password = getpass('Contrasena: ')
    datos = {'correo':correo,'contrasena':password}
    origin = {'Origin':BASE}
    call('/auth/me', expected=401)
    call('/auth/login','POST',datos,expected=403)
    call('/auth/login','POST',{**datos,'contrasena':'incorrecta-de-prueba'},origin,401)
    call('/auth/login','POST',{**datos,'rol':'administrador'},origin,422)
    body = call('/auth/login','POST',datos,origin)
    assert 'access_token' not in body and 'contrasena' not in body['usuario']
    cookie = next(c.value for c in jar if c.name == 'saludmayor_session')
    call('/auth/me')
    call('/auth/logout','POST',expected=403)
    call('/auth/logout','POST',headers=origin)
    call('/auth/me',expected=401)
    call('/auth/me',headers={'Cookie':'saludmayor_session='+cookie},expected=401)
    native = call('/auth/token','POST',datos)
    auth = {'Authorization':'Bearer '+native['access_token']}
    call('/auth/me',headers=auth)
    call('/auth/logout','POST',headers=auth)
    call('/auth/me',headers=auth,expected=401)
    print('PRUEBAS DE AUTENTICACION EXITOSAS')

if __name__ == '__main__':
    main()
