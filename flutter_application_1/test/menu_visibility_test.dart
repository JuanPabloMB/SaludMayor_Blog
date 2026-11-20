import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/session_storage.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/screens/role_home_page.dart';
import 'package:flutter_application_1/screens/publications_page.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

class _Storage extends SessionStorage {
  const _Storage();
  @override
  Future<String?> read() async => null;
}

void main() {
  for (final role in ['administrador', 'usuario']) {
    testWidgets('El menú conserva su estado al ocultarse: $role', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ApiClient(
        storage: const _Storage(),
        client: MockClient((request) async {
          final body = switch (request.url.path) {
            '/mensajes/no-leidos' => '{"total":2}',
            '/panel/resumen' => '{"usuarios_activos":1,"usuarios_inactivos":0,'
                '"publicaciones":0,"categorias_activas":0,'
                '"categorias_inactivas":0,"comentarios":0,"valoraciones":0,'
                '"reacciones":0,"distribucion":[],"recientes":[]}',
            _ => '[]',
          };
          return http.Response(body, 200);
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: RoleHomePage(
          user: UserModel(
            id: 1,
            nombre: 'Cuenta',
            apellidoPaterno: 'Prueba',
            apellidoMaterno: null,
            tipoImagen: null,
            correo: 'prueba@example.com',
            rol: role,
            estado: true,
            fechaRegistro: DateTime(2026),
          ),
          auth: AuthService(api),
          onExit: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final messages = find.widgetWithText(ListTile, 'Mensajes');
      expect(messages, findsOneWidget);
      final badge = find.descendant(of: messages, matching: find.text('2'));
      expect(badge, findsOneWidget);
      expect(tester.getSize(badge).width, lessThan(tester.getSize(messages).width));
      final tile = find.widgetWithText(ListTile, 'Publicaciones');
      await tester.tap(tile);
      await tester.pumpAndSettle();
      final pageState = tester.state(find.byType(PublicationsPage));
      final menuElement = tester.element(tile);
      final sidebar = find.byKey(const ValueKey('menu-lateral-escritorio'));
      final content = find.byKey(const ValueKey('contenido-principal'));
      final header = find.descendant(
        of: sidebar,
        matching: find.text('SaludMayor Blog'),
      );

      void expectMenuLayout() {
        final menuRect = tester.getRect(sidebar);
        final contentRect = tester.getRect(content);
        expect(menuRect.width, 270);
        expect(menuRect.top, contentRect.top);
        expect(menuRect.bottom, contentRect.bottom);
        expect(header, findsOneWidget);
        expect(tester.getTopLeft(header).dy - menuRect.top, lessThan(100));
      }

      expectMenuLayout();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('Ocultar menú'));
        await tester.pumpAndSettle();
        expect(tile, findsNothing);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Mostrar menú'));
        await tester.pumpAndSettle();
        expect(tile, findsOneWidget);
        expect(badge, findsOneWidget);
        expect(tester.element(tile), same(menuElement));
        expectMenuLayout();
        expect(tester.widget<ListTile>(tile).selected, isTrue);
        expect(tester.state(find.byType(PublicationsPage)), same(pageState));
        expect(tester.takeException(), isNull);
      }
      expect(find.widgetWithText(ListTile, 'Usuarios'),
          role == 'administrador' ? findsOneWidget : findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
