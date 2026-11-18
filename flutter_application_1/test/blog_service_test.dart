import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/services/blog_service.dart';

const MethodChannel _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, (
          MethodCall call,
        ) async {
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  group('BlogService', () {
    test('obtiene una lista vacía de publicaciones', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/blog');
        expect(request.method, 'GET');

        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiClient(
        client: client,
        baseUri: Uri.parse('http://localhost:8000/'),
      );

      final result = await BlogService(api).obtenerPublicaciones();

      expect(result, isEmpty);

      api.close();
    });

    test('obtiene categorías activas e inactivas desde la API', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/categorias');
        expect(request.method, 'GET');

        return http.Response(
          '[{"id_categoria":1,"nombre":"Salud","descripcion":null,"estado":true}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiClient(
        client: client,
        baseUri: Uri.parse('http://localhost:8000/'),
      );

      final result = await BlogService(api).obtenerCategorias();

      expect(result, hasLength(1));
      expect(result.single.nombre, 'Salud');
      expect(result.single.estado, isTrue);

      api.close();
    });
  });
}
