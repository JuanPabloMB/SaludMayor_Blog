import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/session_storage.dart';
import 'models/user_model.dart';
import 'screens/welcome_page.dart';
import 'screens/session_page.dart';
import 'services/auth_service.dart';
import 'services/registration_service.dart';
import 'theme/app_theme.dart';
import 'services/branding_service.dart';
import 'widgets/blog_identity.dart';

void main() => runApp(const LoginApp());

class LoginApp extends StatefulWidget {
  const LoginApp({super.key, this.api, this.storage = const SessionStorage()});
  final ApiClient? api;
  final SessionStorage storage;
  @override
  State<LoginApp> createState() => _LoginAppState();
}

class _LoginAppState extends State<LoginApp> {
  late final ApiClient _api = widget.api ?? ApiClient(storage: widget.storage);
  late final AuthService _auth = AuthService(_api, storage: widget.storage);
  String _blogName = 'SaludMayor Blog';
  Uint8List? _logo;
  Future<void> _refreshBranding() async {
    try {
      final service = BrandingService(_api);
      final config = await service.load();
      Uint8List? logo;
      if (config.tieneLogotipo) {
        try {
          logo = await service.logo();
        } catch (_) {
          /* Icono de respaldo. */
        }
      }
      if (mounted) {
        setState(() {
          _blogName = config.nombreApp;
          _logo = logo;
        });
      }
    } catch (_) {
      /* Se conserva la identidad disponible. */
    }
  }

  UserModel? _user;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _restore();
    _refreshBranding();
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final user = await _auth.restore();
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.api == null) {
      _api.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: _blogName,
    builder: (context, child) => BlogIdentity(
      name: _blogName,
      logo: _logo,
      refresh: _refreshBranding,
      child: child ?? const SizedBox.shrink(),
    ),
    theme: AppTheme.light,
    home: _loading
        ? const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Comprobando sesión',
              ),
            ),
          )
        : _failed
        ? Scaffold(
            appBar: AppBar(title: Text(_blogName)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No se pudo comprobar la sesión.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _restore,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          )
        : _user == null
        ? WelcomePage(
            service: RegistrationService(_api),
            auth: _auth,
            onLogin: (user) => setState(() => _user = user),
          )
        : SessionPage(
            user: _user!,
            auth: _auth,
            onExit: () => setState(() => _user = null),
          ),
  );
}
