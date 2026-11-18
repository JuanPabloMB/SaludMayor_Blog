import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/models/valoracion_model.dart';
import 'package:flutter_application_1/models/reaccion_model.dart';
import 'package:flutter_application_1/models/mensaje_model.dart';
import 'package:flutter_application_1/models/configuracion_model.dart';
import 'package:flutter_application_1/models/comentario_model.dart';
import 'package:flutter_application_1/models/auth_model.dart';
import 'package:flutter_application_1/models/request_models.dart';
import 'package:flutter_application_1/models/json_model.dart';

void main() {
  const fecha = '2026-11-18T12:00:00';
  final usuario = <String, dynamic>{
    'id_usuario': 1,
    'nombre': 'María',
    'apellido_paterno': 'García',
    'apellido_materno': null,
    'tipo_imagen': null,
  };
  final completo = {
    ...usuario,
    'correo': 'maria@saludmayor.example',
    'rol': 'usuario',
    'estado': true,
    'fecha_registro': fecha,
  };
  final post = <String, dynamic>{
    'id_blog': 1,
    'id_usuario': 1,
    'id_categoria': 2,
    'titulo': 'Salud',
    'descripcion': 'Cuidados',
    'tipo_imagen': 'image/png',
    'fecha_publicacion': fecha,
    'fecha_actualizacion': null,
    'autor': usuario,
    'categoria': {
      'id_categoria': 2,
      'nombre': 'Salud',
      'descripcion': null,
      'estado': true,
    },
  };
  test('Usuario y sesión web', () {
    final u = UserModel.fromJson(completo);
    expect(u.nombreCompleto, 'María García');
    expect(u.esAdministrador, isFalse);
    expect(
      LoginModel.fromJson({
        'usuario': completo,
        'fecha_expiracion': '${fecha}Z',
      }).fechaExpiracion.isUtc,
      isTrue,
    );
    expect(
      TokenModel.fromJson({
        'access_token': 'test',
        'token_type': 'bearer',
        'expires_in': 3600,
      }).expiresIn,
      3600,
    );
  });
  test('Publicación resumen y detalle', () {
    expect(PostModel.fromJson(post).contenido, isNull);
    final p = PostModel.fromJson({...post, 'contenido': 'Texto completo'});
    expect(p.contenido, 'Texto completo');
    expect(p.categoria.nombre, 'Salud');
    expect(p.tieneImagen, isTrue);
    expect(jsonList([post], PostModel.fromJson).length, 1);
  });
  test('Comentario con autor', () {
    final c = ComentarioModel.fromJson({
      'id_comentario': 1,
      'id_usuario': 1,
      'id_blog': 1,
      'comentario': 'Hola',
      'fecha_comentario': fecha,
      'usuario': usuario,
    });
    expect(c.usuario.nombre, 'María');
  });
  test('Valoraciones vacías y promedio numérico', () {
    expect(
      ValoracionResumen.fromJson({
        'id_blog': 1,
        'promedio': null,
        'total': 0,
        'mi_puntuacion': null,
      }).promedio,
      isNull,
    );
    expect(
      ValoracionResumen.fromJson({
        'id_blog': 1,
        'promedio': 5,
        'total': 1,
        'mi_puntuacion': 5,
      }).promedio,
      5.0,
    );
  });
  test('Reacciones', () {
    final r = ReaccionResumen.fromJson({
      'id_comentario': 1,
      'mi_reaccion': 1,
      'resultados': [
        {
          'tipo_reaccion': {
            'id_tipo_reaccion': 1,
            'nombre': 'Me gusta',
            'emoji': '👍',
            'estado': true,
          },
          'total': 2,
        },
      ],
    });
    expect(r.total, 2);
    expect(r.resultados.first.tipoReaccion.emoji, '👍');
  });
  test('Mensajes y conversaciones', () {
    final m = {
      'id_mensaje': 1,
      'id_emisor': 1,
      'id_receptor': 2,
      'mensaje': 'Hola',
      'fecha_envio': fecha,
      'leido': false,
      'fecha_lectura': null,
      'emisor': usuario,
      'receptor': {...usuario, 'id_usuario': 2},
    };
    final c = ConversacionModel.fromJson({
      'usuario': usuario,
      'ultimo_mensaje': m,
      'no_leidos': 1,
    });
    expect(c.ultimoMensaje.fechaLectura, isNull);
    expect(c.noLeidos, 1);
    expect(MensajesPendientes.fromJson({'total': 1}).total, 1);
  });
  test('Configuración y fechas', () {
    final c = ConfiguracionModel.fromJson({
      'id_configuracion': 1,
      'nombre_app': 'SaludMayor Blog',
      'tipo_imagen': null,
      'fecha_actualizacion': fecha,
    });
    expect(c.tieneLogotipo, isFalse);
    expect(c.fechaActualizacion, DateTime.utc(2026, 11, 18, 12));
    expect(apiDate('2026-11-18T06:00:00-06:00'), c.fechaActualizacion);
  });
  test('Solicitudes sin identidad ni rol manipulables', () {
    expect(RequestModels.comentario(' Hola '), {'comentario': 'Hola'});
    expect(RequestModels.mensaje(2, 'Hola'), {
      'id_receptor': 2,
      'mensaje': 'Hola',
    });
    expect(
      RequestModels.registro(
        nombre: 'María',
        apellidoPaterno: 'García',
        correo: 'maria@example.com',
        contrasena: 'test1234',
      ).containsKey('rol'),
      isFalse,
    );
    expect(() => jsonObject([]), throwsFormatException);
  });
}
