import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/auth_card.dart';
import '../widgets/primary_button.dart';

/// Pantalla de transición hasta la navegación por roles de la fase 3.6.
class SessionPage extends StatefulWidget {
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
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  bool _busy = false;
  String? _message;
  bool _error = false;

  Future<void> _action({required bool logout}) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _error = false;
    });
    try {
      if (logout) {
        await widget.auth.logout();
        if (mounted) {
          widget.onExit();
        }
      } else {
        final user = await widget.auth.restore();
        if (!mounted) {
          return;
        }
        if (user == null) {
          widget.onExit();
        } else {
          setState(() => _message = 'Sesión válida.');
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _message = e.statusCode == null
              ? e.message
              : 'No se pudo completar la operación.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _message = 'No se pudo completar la operación.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SaludMayor Blog')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bienvenido, ${widget.user.nombreCompleto}',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(widget.user.correo, textAlign: TextAlign.center),
                Text(
                  'Rol: ${widget.user.esAdministrador ? 'Administrador' : 'Usuario'}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_message != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _error
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                if (_busy) const Center(child: CircularProgressIndicator()),
                OutlinedButton(
                  onPressed: _busy ? null : () => _action(logout: false),
                  child: const Text('Verificar sesión'),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: 'Cerrar sesión',
                  onPressed: _busy ? null : () => _action(logout: true),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
