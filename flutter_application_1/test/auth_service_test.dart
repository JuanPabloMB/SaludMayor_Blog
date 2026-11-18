import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/session_storage.dart';
import 'package:flutter_application_1/services/auth_service.dart';

class MemoryStorage extends SessionStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> save(String token) async {
    value = token;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

const user = {
  'id_usuario': 1,
  'nombre': 'Ana',
  'apellido_paterno': 'Ruiz',
  'apellido_materno': null,
  'correo': 'ana@example.com',
  'rol': 'administrador',
  'estado': true,
  'tipo_imagen': null,
  'fecha_registro': '2026-11-18T12:00:00',
};

void main() {
  late MemoryStorage storage;
  setUp(() => storage = MemoryStorage());
  AuthService service(MockClient client) {
    final api = ApiClient(client: client, storage: storage);
    addTearDown(api.close);
    return AuthService(api, storage: storage);
  }

  test('Login nativo y recuperación usan Bearer', () async {
    final auth = service(
      MockClient((request) async {
        if (request.url.path == '/auth/token') {
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {
            'correo': 'ana@example.com',
            'contrasena': 'Prueba123!',
          });
          expect(request.headers['Authorization'], isNull);
          return http.Response(
            '{"access_token":"demo","token_type":"bearer","expires_in":3600}',
            200,
          );
        }
        expect(request.url.path, '/auth/me');
        expect(request.headers['Authorization'], 'Bearer demo');
        return http.Response(jsonEncode(user), 200);
      }),
    );
    expect(
      (await auth.login('ana@example.com', 'Prueba123!')).esAdministrador,
      isTrue,
    );
    expect(storage.value, 'demo');
    expect((await auth.restore())?.id, 1);
  });
  test('Credenciales incorrectas no guardan token', () async {
    final auth = service(MockClient((_) async => http.Response('{}', 401)));
    await expectLater(
      auth.login('ana@example.com', 'incorrecta'),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
    expect(storage.value, isNull);
  });
  test('Sesión expirada elimina token', () async {
    storage.value = 'expired';
    final auth = service(MockClient((_) async => http.Response('{}', 401)));
    expect(await auth.restore(), isNull);
    expect(storage.value, isNull);
  });
  test('Cierre confirmado elimina token', () async {
    storage.value = 'demo';
    final auth = service(
      MockClient((request) async {
        expect(request.url.path, '/auth/logout');
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer demo');
        return http.Response('{"mensaje":"Sesion cerrada"}', 200);
      }),
    );
    await auth.logout();
    expect(storage.value, isNull);
  });
  test('Fallo de red no confirma cierre ni borra token', () async {
    storage.value = 'demo';
    final auth = service(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(auth.logout(), throwsA(isA<ApiException>()));
    expect(storage.value, 'demo');
  });
}
