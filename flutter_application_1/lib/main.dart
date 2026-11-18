import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'screens/welcome_page.dart';
import 'services/registration_service.dart';
import 'theme/app_theme.dart';

void main() => runApp(const LoginApp());

class LoginApp extends StatefulWidget {
  const LoginApp({super.key});
  @override
  State<LoginApp> createState() => _LoginAppState();
}

class _LoginAppState extends State<LoginApp> {
  final _api = ApiClient();
  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SaludMayor Blog',
    theme: AppTheme.light,
    home: WelcomePage(service: RegistrationService(_api)),
  );
}
