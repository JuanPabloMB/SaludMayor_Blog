import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../widgets/auth_card.dart';

Future<void> mostrarClave(BuildContext context, String clave) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Guarda tu clave de recuperación'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Guárdala en un lugar seguro. Solo se muestra una vez. No la compartas.',
            ),
            const SizedBox(height: 12),
            SelectableText(clave),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: clave));
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar clave'),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('He guardado la clave'),
        ),
      ],
    ),
  );
}

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({
    super.key,
    required this.api,
    this.correo = '',
    this.renovar = false,
  });
  final ApiClient api;
  final String correo;
  final bool renovar;
  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final _form = GlobalKey<FormState>();
  late final _correo = TextEditingController(text: widget.correo);
  final _clave = TextEditingController();
  final _nueva = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    for (final c in [_correo, _clave, _nueva, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.api.json(
        'POST',
        widget.renovar ? '/usuarios/me/recuperacion' : '/auth/recuperar',
        authenticated: widget.renovar,
        body: widget.renovar
            ? {'contrasena': _clave.text}
            : {
                'correo': _correo.text.trim(),
                'contrasena_actual': _clave.text.trim(),
                'contrasena_nueva': _nueva.text,
              },
      );
      if (!mounted) return;
      if (widget.renovar) {
        await mostrarClave(
          context,
          (result as Map)['clave_recuperacion'] as String,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Contraseña actualizada. Inicia sesión y genera una nueva clave desde tu perfil.',
            ),
          ),
        );
      }
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is ApiException && e.statusCode == 429
            ? 'Demasiados intentos. Espera un minuto.'
            : 'No se pudo completar la operación. Revisa tus datos e inténtalo nuevamente.';
      });
    }
  }

  Widget _field(
    TextEditingController c,
    String label,
    String? Function(String?) validator, {
    bool secret = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      enabled: !_busy,
      obscureText: secret,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.renovar ? 'Clave de recuperación' : 'Recuperar contraseña',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AuthCard(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.renovar
                          ? 'Confirma tu contraseña. La clave anterior dejará de funcionar.'
                          : 'Ingresa tu correo y la clave guardada al registrarte o desde tu perfil.',
                    ),
                    const SizedBox(height: 16),
                    if (!widget.renovar)
                      _field(
                        _correo,
                        'Correo electrónico',
                        (v) => (v ?? '').trim().isEmpty
                            ? 'Ingresa tu correo'
                            : null,
                        secret: false,
                      ),
                    _field(
                      _clave,
                      widget.renovar
                          ? 'Contraseña actual'
                          : 'Clave de recuperación',
                      (v) =>
                          (v ?? '').trim().isEmpty ? 'Campo obligatorio' : null,
                    ),
                    if (!widget.renovar) ...[
                      _field(
                        _nueva,
                        'Nueva contraseña',
                        (v) =>
                            (v ?? '').trim().isEmpty ||
                                v!.runes.length < 8 ||
                                v.runes.length > 128
                            ? 'Usa entre 8 y 128 caracteres'
                            : null,
                      ),
                      _field(
                        _confirm,
                        'Confirmar contraseña',
                        (v) => v != _nueva.text
                            ? 'Las contraseñas no coinciden'
                            : null,
                      ),
                    ],
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(
                        _busy
                            ? 'Procesando...'
                            : widget.renovar
                            ? 'Generar clave'
                            : 'Restablecer contraseña',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
