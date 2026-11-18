"""Pruebas HTTP de permisos. Conserva una cuenta de prueba desactivada."""
from getpass import getpass
from uuid import uuid4
from test_usuarios import call


def main():
    correo_admin = input('Correo del administrador: ').strip()
    clave_admin = getpass('Contrasena del administrador: ')
    admin = call('/auth/token', 'POST', dict(correo=correo_admin, contrasena=clave_admin))['access_token']
    perfil = call('/auth/me', token=admin)
    assert perfil['rol'] == 'administrador'
    correo = f'prueba-roles-{uuid4().hex[:12]}@gmail.com'
    clave = uuid4().hex + '!Aa'
    cuenta = call('/usuarios/registro', 'POST', dict(nombre='Prueba roles', apellido_paterno='Integracion', correo=correo, contrasena=clave), expected=201)
    ruta = f"/usuarios/admin/{cuenta['id_usuario']}"
    def login(expected=200):
        return call('/auth/token', 'POST', dict(correo=correo, contrasena=clave), expected=expected)
    token = login()['access_token']
    otro = login()['access_token']
    call('/usuarios/admin', expected=401)
    call('/usuarios/admin', token=token, expected=403)
    call(ruta, token=token, expected=403)
    call(ruta+'/estado', 'PATCH', {'estado':False}, token, 403)
    call('/usuarios/me', 'PATCH', {'estado':False}, token, 422)
    call('/usuarios/me', 'PATCH', {'rol':'administrador'}, token, 422)
    assert all('contrasena' not in u for u in call('/usuarios/admin', token=admin))
    assert call(ruta, token=admin)['rol']=='usuario'
    call(ruta+'/estado', 'PATCH', {'estado':'false'}, admin, 422)
    call(ruta+'/estado', 'PATCH', {'estado':False,'rol':'administrador'}, admin, 422)
    call(f"/usuarios/admin/{perfil['id_usuario']}/estado", 'PATCH', {'estado':False}, admin, 403)
    assert call(ruta+'/estado', 'PATCH', {'estado':False}, admin)['estado'] is False
    call('/auth/me', token=token, expected=401)
    call('/auth/me', token=otro, expected=401)
    login(401)
    assert call(ruta+'/estado', 'PATCH', {'estado':True}, admin)['estado'] is True
    call('/auth/me', token=token, expected=401)
    token = login()['access_token']
    call('/auth/me', token=token)
    call(ruta+'/estado', 'PATCH', {'estado':False}, admin)
    call('/auth/me', token=token, expected=401)
    call('/auth/logout', 'POST', token=admin)
    print('Cuenta de prueba desactivada:', correo)
    print('PRUEBAS DE ROLES EXITOSAS')

if __name__ == '__main__':
    main()
