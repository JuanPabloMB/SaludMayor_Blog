import 'package:flutter/material.dart';

void main() {
  runApp(const LoginApp());
}

/// Punto de entrada durante la adaptación del proyecto base.
/// Las rutas privadas se incorporarán con la autenticación real.
class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SaludMayor Blog',
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Text('SaludMayor Blog'),
          ),
        ),
      ),
    );
  }
}
