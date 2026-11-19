import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../services/auth_service.dart';

/// Cambia la contraseña y devuelve true si se limpió la sesión local,
/// false si falló esa limpieza, o null si se canceló el formulario.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, required this.auth});

  final AuthService auth;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmacion = TextEditingController();
  final _visible = [false, false, false];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_busy || !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.api.json(
        'PUT',
        '/usuarios/me/contrasena',
        body: {
          'contrasena_actual': _actual.text,
          'contrasena_nueva': _nueva.text,
        },
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = switch (e.statusCode) {
          400 => 'La contraseña actual es incorrecta.',
          401 => 'Tu sesión expiró. Cierra sesión e inicia nuevamente.',
          422 => 'Revisa los requisitos de la nueva contraseña.',
          _ => 'No se pudo cambiar la contraseña. Comprueba tu conexión.',
        };
      });
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = 'No se pudo confirmar el cambio. Comprueba tu conexión.';
      });
      return;
    }
    // El servidor ya revocó todas las sesiones y eliminó la cookie web.
    var limpio = true;
    try {
      await widget.auth.storage.clear();
    } catch (_) {
      limpio = false;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(limpio);
  }

  Widget _campo(
    TextEditingController controller,
    String label,
    int index,
    String? Function(String?) validator,
  ) {
    return TextFormField(
      controller: controller,
      enabled: !_busy,
      obscureText: !_visible[index],
      autocorrect: false,
      enableSuggestions: false,
      maxLength: 128,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _visible[index]
              ? 'Ocultar contraseña'
              : 'Mostrar contraseña',
          onPressed: _busy
              ? null
              : () => setState(() {
                  _visible[index] = !_visible[index];
                }),
          icon: Icon(_visible[index] ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: const Text('Cambiar contraseña'),
        scrollable: true,
        content: SizedBox(
          width: 440,
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Por seguridad, se cerrarán todas tus sesiones al guardar. La nueva contraseña debe tener al menos 8 caracteres.',
                ),
                const SizedBox(height: 20),
                _campo(
                  _actual,
                  'Contraseña actual',
                  0,
                  (v) => v == null || v.isEmpty
                      ? 'Introduce tu contraseña actual.'
                      : null,
                ),
                const SizedBox(height: 16),
                _campo(_nueva, 'Nueva contraseña', 1, (v) {
                  if (v == null ||
                      v.trim().isEmpty ||
                      v.length < 8 ||
                      v.length > 128) {
                    return 'Utiliza entre 8 y 128 caracteres.';
                  }
                  if (v == _actual.text) {
                    return 'Elige una contraseña diferente.';
                  }
                  return null;
                }),
                const SizedBox(height: 16),
                _campo(
                  _confirmacion,
                  'Confirmar nueva contraseña',
                  2,
                  (v) => v != _nueva.text || v == null || v.isEmpty
                      ? 'Las contraseñas no coinciden.'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _busy ? null : _guardar,
            child: Text(_busy ? 'Guardando...' : 'Guardar contraseña'),
          ),
        ],
      ),
    );
  }
}
