import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/theme/app_colors.dart';
import 'package:flutter_application_1/widgets/primary_button.dart';
import 'package:flutter_application_1/widgets/custom_text_field.dart';
import 'package:flutter_application_1/widgets/category_chip.dart';

void main() {
  testWidgets('Arranque e identidad visual', (tester) async {
    await tester.pumpWidget(const LoginApp());
    expect(find.text('SaludMayor Blog'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.primary, AppColors.primary);
    expect(app.theme!.scaffoldBackgroundColor, AppColors.background);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Componentes reutilizables', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              PrimaryButton(text: 'Continuar', onPressed: () => taps++),
              CustomTextField(
                controller: controller,
                label: 'Correo',
                prefixIcon: Icons.email,
              ),
              CategoryChip(text: 'Salud', selected: true, onTap: () => taps++),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Continuar'));
    await tester.enterText(find.byType(TextField), 'prueba');
    await tester.tap(find.text('Salud'));
    expect(taps, 2);
    expect(controller.text, 'prueba');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
