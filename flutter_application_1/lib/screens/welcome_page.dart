import 'package:flutter/material.dart';

import '../services/registration_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_card.dart';
import '../widgets/primary_button.dart';
import 'register_user_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.service});
  final RegistrationService service;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SaludMayor Blog')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AuthCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Bienvenido a SaludMayor',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Salud, bienestar y cuidados para el adulto mayor.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Crear cuenta',
                  onPressed: () async {
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => RegisterPage(service: service),
                      ),
                    );
                    if (created == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cuenta creada correctamente.'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                const OutlinedButton(
                  onPressed: null,
                  child: Text('Iniciar sesión'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El inicio de sesión estará disponible en la siguiente fase.',
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
