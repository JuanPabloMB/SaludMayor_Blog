import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/comentario_model.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/models/valoracion_model.dart';

void main() {
  group('Modelos del detalle de publicación', () {
    test('PostModel interpreta el contenido completo de la API', () {
      final post = PostModel.fromJson({
        'id_blog': 12,
        'id_usuario': 2,
        'id_categoria': 1,
        'titulo': 'Cuidado integral',
        'descripcion': 'Descripción breve',
        'contenido': 'Contenido completo de la publicación.',
        'tipo_imagen': 'image/png',
        'fecha_publicacion': '2026-11-18T10:00:00',
        'fecha_actualizacion': null,
        'autor': {
          'id_usuario': 2,
          'nombre': 'María',
          'apellido_paterno': 'López',
          'apellido_materno': null,
          'tipo_imagen': null,
        },
        'categoria': {
          'id_categoria': 1,
          'nombre': 'Salud',
          'descripcion': null,
          'estado': true,
        },
      });

      expect(post.id, 12);
      expect(post.contenido, 'Contenido completo de la publicación.');
      expect(post.autor.nombreCompleto, 'María López');
      expect(post.categoria.nombre, 'Salud');
      expect(post.tieneImagen, isTrue);
    });

    test('ComentarioModel interpreta autor y fecha', () {
      final comment = ComentarioModel.fromJson({
        'id_comentario': 4,
        'id_usuario': 3,
        'id_blog': 12,
        'comentario': 'Información muy útil.',
        'fecha_comentario': '2026-11-18T11:30:00',
        'usuario': {
          'id_usuario': 3,
          'nombre': 'Carlos',
          'apellido_paterno': 'Pérez',
          'apellido_materno': null,
          'tipo_imagen': null,
        },
      });

      expect(comment.id, 4);
      expect(comment.blogId, 12);
      expect(comment.comentario, 'Información muy útil.');
      expect(comment.usuario.nombreCompleto, 'Carlos Pérez');
    });

    test('ValoracionResumen interpreta promedio y puntuación propia', () {
      final rating = ValoracionResumen.fromJson({
        'id_blog': 12,
        'promedio': 4.5,
        'total': 8,
        'mi_puntuacion': 5,
      });

      expect(rating.blogId, 12);
      expect(rating.promedio, 4.5);
      expect(rating.total, 8);
      expect(rating.miPuntuacion, 5);
    });

    test('ValoracionResumen admite publicación sin valoraciones', () {
      final rating = ValoracionResumen.fromJson({
        'id_blog': 12,
        'promedio': null,
        'total': 0,
        'mi_puntuacion': null,
      });

      expect(rating.promedio, isNull);
      expect(rating.total, 0);
      expect(rating.miPuntuacion, isNull);
    });
  });
}
