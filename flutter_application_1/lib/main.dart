import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

void main() => runApp(const LoginApp());

/// Pantalla temporal hasta integrar la autenticación real.
class LoginApp extends StatelessWidget {
  const LoginApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SaludMayor Blog',
    theme: AppTheme.light,
    home: Scaffold(
      appBar: AppBar(title: const Text('SaludMayor Blog')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Salud, bienestar y cuidados',
                  style: AppTheme.light.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Información para el cuidado del adulto mayor.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
