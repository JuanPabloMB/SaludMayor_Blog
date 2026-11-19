import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'recovery_page.dart';
import '../core/api_exception.dart';
import '../services/registration_service.dart';
import '../widgets/auth_card.dart';
import '../widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.service});
  final RegistrationService? service;
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _paterno = TextEditingController();
  final _materno = TextEditingController();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  ApiClient? _ownedApi;
  late final RegistrationService _service;
  bool _busy = false;
  bool _hidden = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? RegistrationService(_ownedApi = ApiClient());
  }

  @override
  void dispose() {
    for (final controller in [
      _nombre,
      _paterno,
      _materno,
      _correo,
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }
    _ownedApi?.close();
    super.dispose();
  }

  String? _name(String? value, int max, {bool optional = false}) {
    final text = (value ?? '').trim();
    if (text.isEmpty && !optional) {
      return 'Este campo es obligatorio';
    }
    if (text.runes.length > max) {
      return 'Máximo $max caracteres';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String? clave;
      await _service.register(
        onRecoveryKey: (value) => clave = value,
        nombre: _nombre.text,
        apellidoPaterno: _paterno.text,
        apellidoMaterno: _materno.text.trim().isEmpty ? null : _materno.text,
        correo: _correo.text,
        contrasena: _password.text,
      );
      if (!mounted) {
        return;
      }
      if (clave != null) {
        await mostrarClave(context, clave!);
      }
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = switch (error.statusCode) {
          409 => 'El correo ya está registrado.',
          422 => 'Revisa los datos ingresados.',
          500 => 'El servidor no pudo completar el registro.',
          null => error.message,
          _ => 'No se pudo completar el registro.',
        };
        _busy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo confirmar el registro. Verifica tus datos antes de reintentar.';
          _busy = false;
        });
      }
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validator, {
    bool secret = false,
    TextInputType? keyboard,
    List<String>? autofill,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_busy,
      validator: validator,
      keyboardType: keyboard,
      autofillHints: autofill,
      obscureText: secret && _hidden,
      autocorrect: !secret,
      enableSuggestions: !secret,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: secret
            ? IconButton(
                tooltip: _hidden
                    ? 'Mostrar contraseñas'
                    : 'Ocultar contraseñas',
                onPressed: _busy
                    ? null
                    : () => setState(() => _hidden = !_hidden),
                icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
              )
            : null,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crear cuenta')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AuthCard(
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Regístrate',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Completa tus datos. El apellido materno es opcional.',
                    ),
                    const SizedBox(height: 24),
                    _field(
                      _nombre,
                      'Nombre',
                      (v) => _name(v, 100),
                      autofill: [AutofillHints.givenName],
                    ),
                    _field(_paterno, 'Apellido paterno', (v) => _name(v, 60)),
                    _field(
                      _materno,
                      'Apellido materno (opcional)',
                      (v) => _name(v, 60, optional: true),
                    ),
                    _field(
                      _correo,
                      'Correo electrónico',
                      (v) {
                        final text = (v ?? '').trim();
                        return text.length <= 150 &&
                                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(text)
                            ? null
                            : 'Ingresa un correo válido';
                      },
                      keyboard: TextInputType.emailAddress,
                      autofill: [AutofillHints.email],
                    ),
                    _field(
                      _password,
                      'Contraseña',
                      (v) {
                        final text = v ?? '';
                        return text.trim().isEmpty ||
                                text.runes.length < 8 ||
                                text.runes.length > 128
                            ? 'Usa entre 8 y 128 caracteres'
                            : null;
                      },
                      secret: true,
                      autofill: [AutofillHints.newPassword],
                    ),
                    _field(
                      _confirm,
                      'Confirmar contraseña',
                      (v) => v == _password.text && (v ?? '').isNotEmpty
                          ? null
                          : 'Las contraseñas no coinciden',
                      secret: true,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    if (_busy) const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      text: _busy ? 'Registrando...' : 'Registrarme',
                      onPressed: _busy ? null : _submit,
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Volver'),
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
