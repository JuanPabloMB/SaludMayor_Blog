import 'package:flutter/material.dart';

import '../models/legacy/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final direccionController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmarPasswordController = TextEditingController();

  final AuthService authService = AuthService();
  final UserService userService = UserService();

  Map<String, dynamic> _usuarioAdministrador = {};
  bool _argumentoLeido = false;
  bool _esRegistroAdministrativo = false;
  bool _guardando = false;
  int _tipoUsuario = 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentoLeido) return;

    final argumento = ModalRoute.of(context)?.settings.arguments;
    if (argumento is Map<String, dynamic> &&
        argumento['id_usr'] != null &&
        (argumento['tip_usr'] as num? ?? 2).toInt() == 1) {
      _usuarioAdministrador = Map<String, dynamic>.from(argumento);
      _esRegistroAdministrativo = true;
    }
    _argumentoLeido = true;
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    direccionController.dispose();
    passwordController.dispose();
    confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> registrarUsuario() async {
    if (_guardando || !_formKey.currentState!.validate()) return;

    final nombre = nombreController.text.trim();
    final correo = correoController.text.trim();
    final direccion = direccionController.text.trim();
    final password = passwordController.text;

    final mensaje = authService.validarRegistro(
      nombre: nombre,
      correo: correo,
      password: password,
      confirmarpassword: confirmarPasswordController.text,
    );

    if (mensaje != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
      return;
    }

    setState(() => _guardando = true);

    try {
      await userService.agregarUsuario(
        UserModel(
          id: 0,
          nombre: nombre,
          correo: correo,
          password: password,
          direccion: direccion.isEmpty ? null : direccion,
          tipoUsuario: _tipoUsuario,
        ),
      );

      if (!mounted) return;

      if (_esRegistroAdministrativo) {
        Navigator.pushReplacementNamed(
          context,
          '/users',
          arguments: _usuarioAdministrador,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado correctamente')),
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada. Ya puedes iniciar sesión.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo registrar el usuario: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: AuthCard(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 65,
                      color: Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _esRegistroAdministrativo
                          ? 'REGISTRAR USUARIO'
                          : 'CREAR CUENTA',
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08245C),
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: nombreController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 2
                          ? 'Ingresa un nombre válido'
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || !value.trim().contains('@')
                          ? 'Ingresa un correo válido'
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: direccionController,
                      keyboardType: TextInputType.streetAddress,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Dirección (opcional)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<int>(
                      initialValue: _tipoUsuario,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Nivel de usuario',
                        prefixIcon: Icon(Icons.admin_panel_settings),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem<int>(
                          value: 1,
                          child: Text('Nivel 1 — Administrador'),
                        ),
                        DropdownMenuItem<int>(
                          value: 2,
                          child: Text('Nivel 2 — General'),
                        ),
                      ],
                      onChanged: _guardando
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _tipoUsuario = value);
                              }
                            },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.length < 8
                          ? 'La contraseña debe tener al menos 8 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: confirmarPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value != passwordController.text
                          ? 'Las contraseñas no coinciden'
                          : null,
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : registrarUsuario,
                        child: Text(
                          _guardando ? 'REGISTRANDO...' : 'REGISTRARME',
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: _guardando
                          ? null
                          : () {
                              if (_esRegistroAdministrativo) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/users',
                                  arguments: _usuarioAdministrador,
                                );
                              } else {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              }
                            },
                      child: Text(
                        _esRegistroAdministrativo
                            ? 'Volver a gestión de usuarios'
                            : 'Ya tengo una cuenta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
