"""Regresion de recuperacion: usa exclusivamente una cuenta temporal nueva."""
from uuid import uuid4
from test_usuarios import call
from test_auth import call as call_origin, BASE
from test_blog import login


def main():
    admin = login('administrador de pruebas')
    cuenta = None
    correo = f'prueba-rec-{uuid4().hex[:12]}@gmail.com'
    anterior, nueva = uuid4().hex+'!Aa', uuid4().hex+'!Bb'
    def token(clave, expected=200):
        return call('/auth/token', 'POST', dict(correo=correo, contrasena=clave), expected=expected)
    def recuperar(clave, expected=200):
        return call_origin('/auth/recuperar', 'POST', dict(correo=correo,
            contrasena_actual=clave, contrasena_nueva=nueva), {'Origin': BASE}, expected)
    try:
        assert call('/auth/me', token=admin)['rol'] == 'administrador'
        cuenta = call('/usuarios/registro', 'POST', dict(nombre='Prueba recuperacion',
            apellido_paterno='Integracion', correo=correo, contrasena=anterior), expected=201)
        inicial = cuenta['clave_recuperacion']
        assert len(inicial) == 32 and 'recuperacion_hash' not in cuenta
        a, b = token(anterior)['access_token'], token(anterior)['access_token']
        perfil = call('/usuarios/me', token=a)
        assert 'clave_recuperacion' not in perfil and 'recuperacion_hash' not in perfil
        call('/usuarios/me/recuperacion', 'POST', {'contrasena': anterior}, expected=401)
        call('/usuarios/me/recuperacion', 'POST', {'contrasena': 'incorrecta'}, a, 400)
        clave = call('/usuarios/me/recuperacion', 'POST', {'contrasena': anterior}, a)['clave_recuperacion']
        assert clave != inicial and len(clave) == 32
        recuperar(inicial, 400)
        recuperar('incorrecta', 400)
        call('/auth/recuperar', 'POST', dict(correo=correo, contrasena_actual=clave,
            contrasena_nueva=nueva), expected=403)
        recuperar(clave)
        for t in (a,b):
            call('/auth/me', token=t, expected=401)
        token(anterior, 401)
        c = token(nueva)['access_token']
        recuperar(clave, 400)
        call('/auth/logout', 'POST', token=c)
        print('RECUPERACION EXITOSA: clave de un uso y sesiones revocadas')
    finally:
        try:
            if cuenta:
                call(f"/usuarios/admin/{cuenta['id_usuario']}/estado", 'PATCH', {'estado':False}, admin)
                print('Cuenta temporal desactivada:', correo)
        finally:
            call('/auth/logout', 'POST', token=admin)


if __name__ == '__main__':
    main()
