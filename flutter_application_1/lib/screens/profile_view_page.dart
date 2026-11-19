import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/json_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'change_password_dialog.dart';

class ProfileViewPage extends StatefulWidget {
  const ProfileViewPage({
    super.key,
    required this.auth,
    required this.initialUser,
    this.onUserChanged,
    this.onPasswordChanged,
  });

  final AuthService auth;
  final UserModel initialUser;
  final ValueChanged<UserModel>? onUserChanged;
  final VoidCallback? onPasswordChanged;

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  static const int _maxImageSize = 2 * 1024 * 1024;

  late UserModel _user;

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoPaternoController;
  late final TextEditingController _apellidoMaternoController;

  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _fotoBytes;
  Uint8List? _fotoPrevisualizacion;

  bool _loading = false;
  bool _loadingFoto = false;
  bool _uploadingFoto = false;
  bool _deletingFoto = false;
  bool _editing = false;
  bool _picking = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _user = widget.initialUser;

    _nombreController = TextEditingController(text: _user.nombre);
    _apellidoPaternoController = TextEditingController(
      text: _user.apellidoPaterno,
    );
    _apellidoMaternoController = TextEditingController(
      text: _user.apellidoMaterno ?? '',
    );

    _actualizarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    super.dispose();
  }

  void _sincronizarFormulario() {
    _nombreController.text = _user.nombre;
    _apellidoPaternoController.text = _user.apellidoPaterno;
    _apellidoMaternoController.text = _user.apellidoMaterno ?? '';
  }

  Future<void> _actualizarPerfil() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final usuario = await widget.auth.currentUser();

      if (!mounted) return;

      setState(() {
        _user = usuario;
        _loading = false;
      });

      widget.onUserChanged?.call(usuario);
      _sincronizarFormulario();
      await _cargarFoto();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudo actualizar la información del perfil.';
        _loading = false;
      });
    }
  }

  Future<void> _cargarFoto() async {
    if (!_user.tieneFoto) {
      if (mounted) {
        setState(() => _fotoBytes = null);
      }
      return;
    }

    setState(() => _loadingFoto = true);

    try {
      final bytes = await widget.auth.api.bytes('/usuarios/${_user.id}/foto');

      if (!mounted) return;

      setState(() {
        _fotoBytes = bytes;
        _loadingFoto = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _fotoBytes = null;
        _loadingFoto = false;
        _error = 'No se pudo recuperar la fotografía. Actualiza el perfil para reintentar.';
      });
    }
  }

  Future<void> _seleccionarFoto() async {
    if (_bloqueado) return;
    setState(() => _picking = true);

    try {
      final XFile? archivo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (archivo == null || !mounted) return;

      final extension = archivo.name.split('.').last.toLowerCase();

      const formatos = ['jpg', 'jpeg', 'png', 'webp'];

      if (!formatos.contains(extension)) {
        _mostrarMensaje(
          'Formato no permitido. Selecciona una imagen JPG, PNG o WEBP.',
        );
        return;
      }

      final longitud = await archivo.length();
      if (!mounted) return;
      if (longitud > _maxImageSize) {
        _mostrarMensaje('La fotografía supera el límite permitido de 2 MB.');
        return;
      }
      final bytes = await archivo.readAsBytes();
      if (!mounted) return;

      if (bytes.isEmpty) {
        _mostrarMensaje('La imagen seleccionada está vacía.');
        return;
      }

      if (bytes.length > _maxImageSize) {
        _mostrarMensaje('La fotografía supera el límite permitido de 2 MB.');
        return;
      }

      if (!mounted) return;

      setState(() => _fotoPrevisualizacion = bytes);

      await _confirmarFotografia(
        bytes: bytes,
        nombre: archivo.name,
        extension: extension,
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('No se pudo seleccionar la fotografía: $e');
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  Future<void> _confirmarFotografia({
    required Uint8List bytes,
    required String nombre,
    required String extension,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          backgroundColor: const Color(0xFFFFFDF7),
          title: const Text(
            'Vista previa',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.memory(
                  bytes,
                  width: 170,
                  height: 170,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Deseas utilizar esta fotografía en tu perfil?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Text(
                nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.outline, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Guardar fotografía'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmar != true) {
      setState(() => _fotoPrevisualizacion = null);
      return;
    }

    await _subirFoto(bytes: bytes, nombre: nombre, extension: extension);
  }

  Future<void> _subirFoto({
    required Uint8List bytes,
    required String nombre,
    required String extension,
  }) async {
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };

    setState(() {
      _uploadingFoto = true;
      _error = null;
    });

    try {
      final resultado = await widget.auth.api.uploadFile(
        'PUT',
        '/usuarios/me/foto',
        bytes: bytes,
        fileName: nombre,
        mimeType: mimeTypes[extension]!,
        fieldName: 'archivo',
      );

      final usuario = UserModel.fromJson(jsonObject(resultado));

      if (!mounted) return;

      setState(() {
        _user = usuario;
        _fotoBytes = bytes;
        _fotoPrevisualizacion = null;
        _uploadingFoto = false;
      });

      widget.onUserChanged?.call(usuario);
      _mostrarMensaje('Tu fotografía se guardó correctamente.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _fotoPrevisualizacion = null;
        _uploadingFoto = false;
        _error = 'No se pudo guardar la fotografía: $e';
      });
    }
  }

  Future<void> _eliminarFoto() async {
    if (_bloqueado) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFDF7),
          title: const Text('Eliminar fotografía'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar tu fotografía de perfil?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      _deletingFoto = true;
      _error = null;
    });

    try {
      final resultado = await widget.auth.api.json(
        'DELETE',
        '/usuarios/me/foto',
      );

      final usuario = UserModel.fromJson(jsonObject(resultado));

      if (!mounted) return;

      setState(() {
        _user = usuario;
        _fotoBytes = null;
        _fotoPrevisualizacion = null;
        _deletingFoto = false;
      });

      widget.onUserChanged?.call(usuario);
      _mostrarMensaje('Tu fotografía se eliminó correctamente.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _deletingFoto = false;
        _error = 'No se pudo eliminar la fotografía: $e';
      });
    }
  }

  Future<void> _guardarCambios() async {
    final nombre = _nombreController.text.trim();
    final apellidoPaterno = _apellidoPaternoController.text.trim();
    final apellidoMaterno = _apellidoMaternoController.text.trim();

    if (nombre.isEmpty || apellidoPaterno.isEmpty) {
      _mostrarMensaje('El nombre y apellido paterno son obligatorios.');
      return;
    }

    if (nombre.length > 100 ||
        apellidoPaterno.length > 60 ||
        apellidoMaterno.length > 60) {
      _mostrarMensaje('El nombre admite 100 caracteres y cada apellido 60.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final usuario = await widget.auth.updateProfile(
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
      );

      if (!mounted) return;

      setState(() {
        _user = usuario;
        _loading = false;
        _editing = false;
      });

      widget.onUserChanged?.call(usuario);
      _sincronizarFormulario();
      _mostrarMensaje('Tu información se actualizó correctamente.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'No se pudieron guardar los cambios: $e';
      });
    }
  }

  void _cancelarEdicion() {
    _sincronizarFormulario();

    setState(() {
      _editing = false;
      _error = null;
    });
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  String _fechaRegistro(DateTime fecha) {
    final local = fecha.toLocal();
    final dia = local.day.toString().padLeft(2, '0');

    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '$dia de ${meses[local.month - 1]} de ${local.year}';
  }

  String _iniciales() {
    final nombre = _user.nombre.trim();
    final apellido = _user.apellidoPaterno.trim();

    final primera = nombre.isNotEmpty ? nombre[0] : '';
    final segunda = apellido.isNotEmpty ? apellido[0] : '';

    return '$primera$segunda'.toUpperCase();
  }

  bool get _procesandoFoto => _uploadingFoto || _deletingFoto;
  bool get _bloqueado =>
      _loading || _loadingFoto || _procesandoFoto || _picking || _editing;

  Future<void> _cambiarContrasena() async {
    if (_bloqueado) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangePasswordDialog(auth: widget.auth),
    );
    if (!mounted || result == null) return;
    _mostrarMensaje(
      result ? 'Contraseña actualizada. Inicia sesión nuevamente.' : 'Contraseña actualizada. No se pudo limpiar el token local; inicia sesión nuevamente.',
    );
    widget.onPasswordChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _encabezado(theme),
                  const SizedBox(height: 24),
                  _tarjetaIdentidad(theme),
                  const SizedBox(height: 20),
                  if (_editing) _formularioEdicion(theme),
                  if (!_editing) _tarjetaInformacion(theme),
                  const SizedBox(height: 20),
                  _tarjetaCuenta(theme),
                  if (widget.onPasswordChanged != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _bloqueado ? null : _cambiarContrasena,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Cambiar contraseña'),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _mensajeError(),
                  ],
                  const SizedBox(height: 20),
                  if (!_editing)
                    FilledButton.icon(
                      onPressed: _bloqueado
                          ? null
                          : () {
                              setState(() {
                                _editing = true;
                                _error = null;
                              });
                            },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar información personal'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _bloqueado ? null : _actualizarPerfil,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _loading ? 'Procesando...' : 'Actualizar información',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: AppColors.primary),
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

  Widget _encabezado(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFDCE9D9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.person_outline,
            size: 30,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi perfil',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Consulta y administra tu información personal',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tarjetaIdentidad(ThemeData theme) {
    final foto = _fotoPrevisualizacion ?? _fotoBytes;

    return Card(
      color: AppColors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E5D9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: const Color(0xFFDCE9D9),
                  backgroundImage: foto != null ? MemoryImage(foto) : null,
                  child: foto == null
                      ? _loadingFoto
                            ? const CircularProgressIndicator(
                                color: AppColors.primary,
                              )
                            : Text(
                                _iniciales().isEmpty ? '?' : _iniciales(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                      : null,
                ),
                if (_procesandoFoto)
                  const Positioned.fill(
                    child: CircleAvatar(
                      backgroundColor: Color(0x99000000),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: 'Cambiar fotografía',
                    onPressed: _bloqueado ? null : _seleccionarFoto,
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _user.nombreCompleto,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _user.correo,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EFE4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _user.esAdministrador ? 'Administrador' : 'Usuario',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _bloqueado ? null : _seleccionarFoto,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _user.tieneFoto
                        ? 'Cambiar fotografía'
                        : 'Agregar fotografía',
                  ),
                ),
                if (_user.tieneFoto || _fotoBytes != null)
                  TextButton.icon(
                    onPressed: _bloqueado ? null : _eliminarFoto,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                    label: const Text(
                      'Eliminar',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'JPG, PNG o WEBP. Tamaño máximo: 2 MB.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.outline, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaInformacion(ThemeData theme) {
    return Card(
      color: AppColors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E5D9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información personal',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _dato(
              icono: Icons.badge_outlined,
              etiqueta: 'Nombre',
              valor: _user.nombre,
            ),
            _separador(),
            _dato(
              icono: Icons.person_outline,
              etiqueta: 'Apellido paterno',
              valor: _user.apellidoPaterno,
            ),
            _separador(),
            _dato(
              icono: Icons.person_outline,
              etiqueta: 'Apellido materno',
              valor: _user.apellidoMaterno?.isNotEmpty == true
                  ? _user.apellidoMaterno!
                  : 'No registrado',
            ),
            _separador(),
            _dato(
              icono: Icons.email_outlined,
              etiqueta: 'Correo electrónico',
              valor: _user.correo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _formularioEdicion(ThemeData theme) {
    return Card(
      color: AppColors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E5D9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Editar información personal',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Completa tus datos. El nombre y el apellido paterno son obligatorios.',
              style: TextStyle(color: AppColors.outline),
            ),
            const SizedBox(height: 22),
            _campo(
              controller: _nombreController,
              etiqueta: 'Nombre',
              icono: Icons.badge_outlined,
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            _campo(
              controller: _apellidoPaternoController,
              etiqueta: 'Apellido paterno',
              icono: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _campo(
              controller: _apellidoMaternoController,
              etiqueta: 'Apellido materno',
              icono: Icons.person_outline,
              obligatorio: false,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading ? null : _guardarCambios,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_loading ? 'Guardando...' : 'Guardar cambios'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _loading ? null : _cancelarEdicion,
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String etiqueta,
    required IconData icono,
    bool obligatorio = true,
    int maxLength = 60,
  }) {
    return TextField(
      controller: controller,
      enabled: !_loading,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: obligatorio ? etiqueta : '$etiqueta (opcional)',
        prefixIcon: Icon(icono),
        filled: true,
        fillColor: AppColors.background,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _tarjetaCuenta(ThemeData theme) {
    return Card(
      color: AppColors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E5D9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la cuenta',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _dato(
              icono: Icons.numbers,
              etiqueta: 'Identificador de usuario',
              valor: '${_user.id}',
            ),
            _separador(),
            _dato(
              icono: Icons.admin_panel_settings_outlined,
              etiqueta: 'Tipo de cuenta',
              valor: _user.esAdministrador ? 'Administrador' : 'Usuario',
            ),
            _separador(),
            _dato(
              icono: Icons.verified_user_outlined,
              etiqueta: 'Estado',
              valor: _user.estado ? 'Activa' : 'Inactiva',
              colorValor: _user.estado
                  ? AppColors.successText
                  : AppColors.errorText,
            ),
            _separador(),
            _dato(
              icono: Icons.calendar_month_outlined,
              etiqueta: 'Fecha de registro',
              valor: _fechaRegistro(_user.fechaRegistro),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato({
    required IconData icono,
    required String etiqueta,
    required String valor,
    Color? colorValor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: AppColors.primary, size: 23),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: const TextStyle(color: AppColors.outline, fontSize: 13),
              ),
              const SizedBox(height: 4),
              SelectableText(
                valor,
                style: TextStyle(
                  color: colorValor ?? AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _separador() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 15),
      child: Divider(height: 1, color: Color(0xFFE8E8DF)),
    );
  }

  Widget _mensajeError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6B9A8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.errorText),
            ),
          ),
        ],
      ),
    );
  }
}
