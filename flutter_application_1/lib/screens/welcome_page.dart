import 'package:flutter/material.dart';

import '../services/registration_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_user_page.dart';
import '../widgets/blog_identity.dart';
import '../widgets/auth_card.dart';
import '../widgets/primary_button.dart';
import 'register_user_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.service,
    required this.auth,
    required this.onLogin,
  });
  final RegistrationService service;
  final AuthService auth;
  final ValueChanged<UserModel> onLogin;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(BlogIdentity.nameOf(context))),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AuthCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BlogLogo(size: 80),
                const SizedBox(height: 20),
                Text(
                  'Bienvenido a ${BlogIdentity.nameOf(context)}',
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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final user = await Navigator.of(context).push<UserModel>(
                        MaterialPageRoute(
                          builder: (_) => LoginPage(service: auth),
                        ),
                      );
                      if (user != null && context.mounted) {
                        onLogin(user);
                      }
                    },
                    child: const Text('Iniciar sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
