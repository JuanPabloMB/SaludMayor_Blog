import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/services/connection_service.dart';

void main() {
  ApiClient create(http.Client client) {
    final api = ApiClient(
      client: client,
      baseUri: Uri.parse('http://localhost:8000/'),
    );
    addTearDown(api.close);
    return api;
  }

  test('Conexión API y configuración', () async {
    final api = create(
      MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        if (request.url.path == '/') {
          return http.Response('{"version":"1.0.0"}', 200);
        }
        expect(request.url.path, '/configuracion');
        return http.Response(
          '{"id_configuracion":1,"nombre_app":"SaludMayor Blog"}',
          200,
        );
      }),
    );
    expect(await ConnectionService(api).check(), 'SaludMayor Blog · API 1.0.0');
  });
  test('Error HTTP conserva código', () async {
    final api = create(
      MockClient((_) async => http.Response('{"detail":"Sin permiso"}', 403)),
    );
    await expectLater(
      api.json('GET', '/', authenticated: false),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
      ),
    );
  });
  test('JSON inválido', () async {
    final api = create(MockClient((_) async => http.Response('invalid', 200)));
    await expectLater(
      api.json('GET', '/', authenticated: false),
      throwsA(isA<ApiException>()),
    );
  });
  test('Servidor inaccesible', () async {
    final api = create(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      api.json('GET', '/', authenticated: false),
      throwsA(isA<ApiException>()),
    );
  });
  test('Datos binarios', () async {
    final api = create(
      MockClient((_) async => http.Response.bytes([1, 2, 3], 200)),
    );
    expect(await api.bytes('/configuracion/logotipo', authenticated: false), [
      1,
      2,
      3,
    ]);
  });
}
