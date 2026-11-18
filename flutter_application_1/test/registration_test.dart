import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/services/registration_service.dart';

void main() {
  test('Registro público sin rol ni identificador', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/usuarios/registro');
        expect(request.headers['Authorization'], isNull);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.keys.toSet(), {
          'nombre',
          'apellido_paterno',
          'apellido_materno',
          'correo',
          'contrasena',
        });
        expect(body['apellido_materno'], isNull);
        return http.Response(
          jsonEncode({
            'id_usuario': 100,
            'nombre': 'Ana',
            'apellido_paterno': 'Ruiz',
            'apellido_materno': null,
            'correo': 'ana@example.com',
            'rol': 'usuario',
            'estado': true,
            'tipo_imagen': null,
            'fecha_registro': '2026-11-18T12:00:00',
          }),
          201,
        );
      }),
    );
    addTearDown(api.close);
    final user = await RegistrationService(api).register(
      nombre: 'Ana',
      apellidoPaterno: 'Ruiz',
      correo: 'ana@example.com',
      contrasena: 'Prueba123!',
    );
    expect(user.esAdministrador, isFalse);
    expect(user.nombreCompleto, 'Ana Ruiz');
  });
  test('Correo duplicado conserva estado 409', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response('{"detail":"Correo duplicado"}', 409),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      RegistrationService(api).register(
        nombre: 'Ana',
        apellidoPaterno: 'Ruiz',
        correo: 'ana@example.com',
        contrasena: 'Prueba123!',
      ),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409),
      ),
    );
  });
}
