import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/session_storage.dart';
import 'package:flutter_application_1/screens/admin_categories_page.dart';
import 'package:flutter_application_1/screens/welcome_page.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/registration_service.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

class _Storage extends SessionStorage {
  const _Storage();
  @override
  Future<String?> read() async => null;
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(640, 360),
    const Size(1280, 800),
  ]) {
    testWidgets('Bienvenida adaptable $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ApiClient(
        client: MockClient((_) async => http.Response('[]', 200)),
        storage: const _Storage(),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: WelcomePage(
            service: RegistrationService(api),
            auth: AuthService(api),
            onLogin: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Categorías en pantalla horizontal con texto ampliado', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(640, 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          '[{"id_categoria":1,"nombre":"Salud","descripcion":"Bienestar","estado":true}]',
          200,
        ),
      ),
      storage: const _Storage(),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(body: AdminCategoriesPage(api: api)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Salud'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Salud'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
