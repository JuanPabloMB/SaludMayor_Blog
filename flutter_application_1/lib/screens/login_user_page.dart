import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import 'recovery_page.dart';
import '../services/auth_service.dart';
import '../widgets/auth_card.dart';
import '../widgets/primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.service});
  final AuthService service;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidden = true;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _password.dispose();
    super.dispose();
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
      final user = await widget.service.login(_correo.text, _password.text);
      if (!mounted) {
        return;
      }
      _password.clear();
      setState(() => _busy = false);
      Navigator.of(context).pop(user);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = switch (error.statusCode) {
            401 => 'Correo o contraseña incorrectos, o cuenta no disponible.',
            403 => 'No se autorizó el acceso. Verifica la configuración del servidor.',
            422 => 'Revisa los datos ingresados.',
            null => error.message,
            _ => 'No se pudo iniciar sesión.',
          };
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'No se pudo confirmar la sesión. Intenta nuevamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
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
                      Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Accede a tu cuenta',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _correo,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          final text = (v ?? '').trim();
                          return text.length <= 150 &&
                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(text)
                              ? null
                              : 'Ingresa un correo válido';
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: _hidden,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.password],
                        validator: (v) =>
                            (v ?? '').isEmpty || v!.runes.length > 128
                            ? 'Ingresa tu contraseña (máximo 128 caracteres)'
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _hidden
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: _busy
                                ? null
                                : () => setState(() => _hidden = !_hidden),
                            icon: Icon(
                              _hidden ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => RecoveryPage(
                                    api: widget.service.api,
                                    correo: _correo.text,
                                  ),
                                ),
                              ),
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
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
                      const SizedBox(height: 24),
                      if (_busy)
                        const Center(child: CircularProgressIndicator()),
                      PrimaryButton(
                        text: _busy ? 'Ingresando...' : 'Iniciar sesión',
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
    ),
  );
}
