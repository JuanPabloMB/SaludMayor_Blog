import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Arranque de SaludMayor Blog', (tester) async {
    await tester.pumpWidget(const LoginApp());
    expect(find.text('SaludMayor Blog'), findsOneWidget);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        'SaludMayor Blog');
    expect(tester.takeException(), isNull);
  });
}
