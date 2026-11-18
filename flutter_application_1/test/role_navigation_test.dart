import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Navegación por roles', () {
    test('el administrador dispone de cinco módulos de navegación', () {
      const adminItems = [
        'Inicio',
        'Publicaciones',
        'Usuarios',
        'Categorías',
        'Configuración',
      ];
      expect(adminItems.length, 5);
      expect(adminItems, contains('Usuarios'));
      expect(adminItems, contains('Configuración'));
    });

    test('el usuario normal no dispone de módulos administrativos', () {
      const userItems = ['Inicio', 'Publicaciones', 'Mi perfil', 'Mensajes'];
      expect(userItems.length, 4);
      expect(userItems, isNot(contains('Usuarios')));
      expect(userItems, isNot(contains('Configuración')));
      expect(userItems, isNot(contains('Categorías')));
    });
  });
}
