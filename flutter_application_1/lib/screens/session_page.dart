import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'role_home_page.dart';

/// Punto de entrada posterior a una autenticación válida.
class SessionPage extends StatelessWidget {
  const SessionPage({
    super.key,
    required this.user,
    required this.auth,
    required this.onExit,
  });

  final UserModel user;
  final AuthService auth;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return RoleHomePage(user: user, auth: auth, onExit: onExit);
  }
}
