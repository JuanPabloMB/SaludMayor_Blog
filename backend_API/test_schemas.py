"""Pruebas de validacion y serializacion. No modifica MySQL."""
from datetime import datetime
from types import SimpleNamespace
from pydantic import ValidationError
from schemas import (UsuarioRegistro, UsuarioActualizar, UsuarioRespuesta,
                     LoginSolicitud, BlogCrear, BlogActualizar, BlogRespuesta,
                     ComentarioCrear, ValoracionGuardar, ReaccionGuardar,
                     MensajeCrear, ConfiguracionActualizar, SesionRespuesta)


def rechazar(clase, datos):
    try:
        clase.model_validate(datos)
    except ValidationError:
        print(f'OK rechazo: {clase.__name__}')
    else:
        raise AssertionError(f'Datos invalidos aceptados: {clase.__name__}')


def main():
    registro = dict(nombre=' Maria ', apellido_paterno='Garcia',
                    correo='maria@example.com', contrasena='Prueba123!')
    usuario = UsuarioRegistro(**registro)
    assert usuario.nombre == 'Maria'
    assert usuario.contrasena.get_secret_value() == 'Prueba123!'
    print('OK registro y limpieza de texto')
    rechazar(UsuarioRegistro, {**registro, 'rol': 'administrador'})
    rechazar(UsuarioRegistro, {**registro, 'correo': 'incorrecto'})
    rechazar(UsuarioRegistro, {**registro, 'contrasena': '123'})
    rechazar(UsuarioRegistro, {**registro, 'contrasena': '        '})
    rechazar(UsuarioActualizar, {})
    rechazar(UsuarioActualizar, {'nombre': None})
    assert UsuarioActualizar(apellido_materno=None).model_dump(exclude_unset=True) == {'apellido_materno': None}
    LoginSolicitud(correo='maria@example.com', contrasena='Prueba123!')
    LoginSolicitud(correo='admin@saludmayor.example', contrasena='Prueba123!')
    rechazar(LoginSolicitud, {'correo': 'incorrecto', 'contrasena': 'Prueba123!'})
    BlogCrear(id_categoria=1, titulo='Salud', descripcion='Resumen', contenido='Contenido')
    rechazar(BlogCrear, dict(id_categoria=0, titulo='Salud', descripcion='Resumen', contenido='Contenido'))
    rechazar(BlogActualizar, {'titulo': ' '})
    rechazar(ComentarioCrear, {'comentario': '  '})
    rechazar(ComentarioCrear, {'comentario': 'Hola', 'id_usuario': 1})
    for puntos in (1, 5):
        assert ValoracionGuardar(puntuacion=puntos).puntuacion == puntos
    for puntos in (0, 6, 2.5, True, '5'):
        rechazar(ValoracionGuardar, {'puntuacion': puntos})
    rechazar(ReaccionGuardar, {'id_tipo_reaccion': 0})
    rechazar(MensajeCrear, {'id_receptor': 2, 'mensaje': ' '})
    rechazar(MensajeCrear, {'id_receptor': 2, 'mensaje': 'Hola', 'id_emisor': 1})
    rechazar(ConfiguracionActualizar, {'nombre_app': ' '})
    ahora = datetime.now()
    orm = SimpleNamespace(id_usuario=1, nombre='Maria', apellido_paterno='Garcia',
                          apellido_materno=None, correo='maria@saludmayor.example',
                          rol='usuario', estado=True, fecha_registro=ahora,
                          tipo_imagen='image/png', foto_perfil=b'png', contrasena='hash')
    salida = UsuarioRespuesta.model_validate(orm).model_dump()
    assert 'contrasena' not in salida and 'foto_perfil' not in salida
    blog = SimpleNamespace(id_blog=1, id_usuario=1, id_categoria=1, titulo='Salud',
                           descripcion='Resumen', contenido='Contenido', tipo_imagen='image/png',
                           imagen=b'png', fecha_publicacion=ahora, fecha_actualizacion=None,
                           autor=orm, categoria=SimpleNamespace(id_categoria=1, nombre='Salud', descripcion=None, estado=True))
    datos = BlogRespuesta.model_validate(blog).model_dump()
    assert 'imagen' not in datos and 'correo' not in datos['autor'] and 'contrasena' not in datos['autor']
    sesion = SimpleNamespace(id_sesion=1, fecha_inicio=ahora, fecha_expiracion=ahora,
                            fecha_cierre=None, revocada=False, identificador_token='privado')
    assert 'identificador_token' not in SesionRespuesta.model_validate(sesion).model_dump()
    print('OK respuestas sin contrasenas, identificadores de token ni binarios')
    print('PRUEBAS DE ESQUEMAS EXITOSAS')


if __name__ == '__main__':
    main()
