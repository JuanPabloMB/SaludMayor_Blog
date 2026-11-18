import 'package:flutter/material.dart';

class PasswordPage extends StatelessWidget {
  const PasswordPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Contraseña')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'La recuperación de contraseña no está disponible.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
