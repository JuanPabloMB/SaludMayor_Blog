import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/services/blog_service.dart';

const MethodChannel secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

Map<String, dynamic> blogResponse({int id = 7}) => {
  'id_blog': id,
  'id_usuario': 1,
  'id_categoria': 1,
  'titulo': 'Publicación de prueba',
  'descripcion': 'Descripción de prueba',
  'contenido': 'Contenido completo de prueba',
  'tipo_imagen': null,
  'fecha_publicacion': '2026-11-18T10:00:00',
  'fecha_actualizacion': null,
  'autor': {
    'id_usuario': 1,
    'nombre': 'Administrador',
    'apellido_paterno': 'SaludMayor',
    'apellido_materno': null,
    'tipo_imagen': null,
  },
  'categoria': {
    'id_categoria': 1,
    'nombre': 'Salud',
    'descripcion': null,
    'estado': true,
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  group('BlogService CRUD', () {
    test('crea una publicación enviando los campos esperados', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/blog');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['id_categoria'], 1);
        expect(body['titulo'], 'Publicación de prueba');
        expect(body['descripcion'], 'Descripción de prueba');
        expect(body['contenido'], 'Contenido completo de prueba');
        return http.Response(
          jsonEncode(blogResponse()),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiClient(
        client: client,
        baseUri: Uri.parse('http://localhost:8000/'),
      );

      final post = await BlogService(api).crear(
        idCategoria: 1,
        titulo: ' Publicación de prueba ',
        descripcion: ' Descripción de prueba ',
        contenido: ' Contenido completo de prueba ',
      );

      expect(post.id, 7);
      expect(post.titulo, 'Publicación de prueba');
      api.close();
    });

    test('actualiza una publicación mediante PATCH', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/blog/7');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['titulo'], 'Título actualizado');
        return http.Response(
          jsonEncode(blogResponse()),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiClient(
        client: client,
        baseUri: Uri.parse('http://localhost:8000/'),
      );

      final post = await BlogService(api).actualizar(
        7,
        idCategoria: 1,
        titulo: 'Título actualizado',
        descripcion: 'Descripción actualizada',
        contenido: 'Contenido actualizado',
      );

      expect(post.id, 7);
      api.close();
    });

    test('elimina una publicación mediante DELETE', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/blog/7');
        return http.Response(
          jsonEncode({'mensaje': 'Publicacion eliminada'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiClient(
        client: client,
        baseUri: Uri.parse('http://localhost:8000/'),
      );

      await expectLater(BlogService(api).eliminar(7), completes);
      api.close();
    });
  });
}
