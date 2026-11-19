import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/user_model.dart';
import '../services/admin_user_service.dart';
import '../theme/app_colors.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key, required this.api});
  final ApiClient api;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late final AdminUserService _service;
  final _buscar = TextEditingController();
  List<UserModel> _usuarios = [];
  bool _loading = false;
  bool _detalle = false;
  String? _error;
  String _rol = 'todos';
  String _estado = 'todos';
  int _limite = 50;

  @override
  void initState() {
    super.initState();
    _service = AdminUserService(widget.api);
    _cargar();
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (_loading || _detalle) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final usuarios = await _service.listarTodos();
      if (!mounted) {
        return;
      }
      setState(() {
        _usuarios = usuarios;
        _limite = 50;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'No se pudieron actualizar las cuentas: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _normalizar(String value) {
    var texto = value.toLowerCase().trim();
    const origen = 'áéíóúü';
    const destino = 'aeiouu';
    for (var i = 0; i < origen.length; i++) {
      texto = texto.replaceAll(origen[i], destino[i]);
    }
    return texto;
  }

  List<UserModel> get _filtrados {
    final consulta = _normalizar(_buscar.text);
    return _usuarios.where((u) {
      final texto = _normalizar('${u.nombreCompleto} ${u.correo} ${u.id}');
      return texto.contains(consulta) &&
          (_rol == 'todos' || u.rol == _rol) &&
          (_estado == 'todos' || u.estado == (_estado == 'activa'));
    }).toList();
  }

  Future<void> _abrir(UserModel usuario) async {
    if (_loading || _detalle) {
      return;
    }
    setState(() => _detalle = true);
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DetalleUsuario(
          service: _service,
          id: usuario.id,
          onChanged: (actualizado) {
            if (!mounted) {
              return;
            }
            setState(
              () => _usuarios = _usuarios
                  .map((u) => u.id == actualizado.id ? actualizado : u)
                  .toList(),
            );
          },
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _detalle = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 32,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Usuarios',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const Text('Administra las cuentas registradas'),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Actualizar usuarios',
                      onPressed: _loading || _detalle ? null : _cargar,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _buscar,
                  onChanged: (_) => setState(() => _limite = 50),
                  decoration: InputDecoration(
                    labelText: 'Buscar nombre, correo o ID',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _buscar.clear();
                        setState(() => _limite = 50);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _filtro(
                      'Rol',
                      _rol,
                      const {
                        'todos': 'Todos',
                        'administrador': 'Administrador',
                        'usuario': 'Usuario',
                      },
                      (v) => setState(() {
                        _rol = v;
                        _limite = 50;
                      }),
                    ),
                    _filtro(
                      'Estado',
                      _estado,
                      const {
                        'todos': 'Todos',
                        'activa': 'Activa',
                        'inactiva': 'Inactiva',
                      },
                      (v) => setState(() {
                        _estado = v;
                        _limite = 50;
                      }),
                    ),
                    TextButton(
                      onPressed: () {
                        _buscar.clear();
                        setState(() {
                          _rol = 'todos';
                          _estado = 'todos';
                          _limite = 50;
                        });
                      },
                      child: const Text('Restablecer filtros'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loading) const LinearProgressIndicator(),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.errorText),
                  ),
                  OutlinedButton(
                    onPressed: _loading ? null : _cargar,
                    child: const Text('Reintentar'),
                  ),
                ],
                Text(
                  '${filtrados.length} de ${_usuarios.length} cuentas${_error != null ? ' (última carga disponible)' : ''}',
                ),
                const SizedBox(height: 12),
                if (!_loading && _error == null && filtrados.isEmpty)
                  const Text('No se encontraron cuentas.'),
                for (final u in filtrados.take(_limite))
                  Card(
                    color: AppColors.surface,
                    child: ListTile(
                      enabled: !_loading && !_detalle,
                      onTap: () => _abrir(u),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.primary,
                        child: Icon(
                          u.esAdministrador
                              ? Icons.admin_panel_settings_outlined
                              : Icons.person_outline,
                        ),
                      ),
                      title: Text(
                        u.nombreCompleto,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.correo),
                          Text(
                            'ID: ${u.id} · ${u.esAdministrador ? 'Administrador' : 'Usuario'}',
                          ),
                          Text(
                            u.estado ? 'Activa' : 'Inactiva',
                            style: TextStyle(
                              color: u.estado
                                  ? AppColors.successText
                                  : AppColors.errorText,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                if (filtrados.length > _limite)
                  OutlinedButton(
                    onPressed: () => setState(() => _limite += 50),
                    child: const Text('Mostrar más usuarios'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filtro(
    String label,
    String value,
    Map<String, String> opciones,
    ValueChanged<String> cambiar,
  ) => SizedBox(
    width: 220,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: opciones.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              cambiar(v);
            }
          },
        ),
      ],
    ),
  );
}

class _DetalleUsuario extends StatefulWidget {
  const _DetalleUsuario({
    required this.service,
    required this.id,
    required this.onChanged,
  });
  final AdminUserService service;
  final int id;
  final ValueChanged<UserModel> onChanged;
  @override
  State<_DetalleUsuario> createState() => _DetalleUsuarioState();
}

class _DetalleUsuarioState extends State<_DetalleUsuario> {
  UserModel? _usuario;
  Widget? _foto;
  bool _busy = false;
  String? _error;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _busy = true;
      _error = null;
      _aviso = null;
      _foto = null;
    });
    try {
      final u = await widget.service.consultar(widget.id);
      if (!mounted) {
        return;
      }
      setState(() => _usuario = u);
      widget.onChanged(u);
      await _cargarFoto(u);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo consultar la cuenta: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _cargarFoto(UserModel u) async {
    if (!u.estado || !u.tieneFoto) {
      return;
    }
    try {
      final bytes = await widget.service.foto(u.id);
      if (!mounted) {
        return;
      }
      setState(
        () => _foto = ClipOval(
          child: Image.memory(
            bytes,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) =>
                const CircleAvatar(radius: 44, child: Icon(Icons.person)),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _aviso = 'No se pudo recuperar la fotografía.');
      }
    }
  }

  Future<void> _cambiar() async {
    final u = _usuario;
    if (_busy || u == null || u.esAdministrador) {
      return;
    }
    final activar = !u.estado;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activar ? 'Activar cuenta' : 'Desactivar cuenta'),
        content: Text(
          activar
              ? '¿Permitir que ${u.nombreCompleto} vuelva a iniciar sesión?'
              : '¿Desactivar a ${u.nombreCompleto}? Se revocarán sus sesiones. Sus datos se conservarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _aviso = null;
    });
    try {
      final actualizado = await widget.service.cambiarEstado(u.id, activar);
      if (!mounted) {
        return;
      }
      setState(() {
        _usuario = actualizado;
        _foto = null;
        _aviso = actualizado.estado
            ? 'Cuenta activada.'
            : 'Cuenta desactivada.';
      });
      widget.onChanged(actualizado);
      await _cargarFoto(actualizado);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo confirmar el cambio: $e. Actualiza el detalle antes de reintentar.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _usuario;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('Detalle de usuario'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_busy) const LinearProgressIndicator(),
                if (u != null) ...[
                  Center(
                    child:
                        _foto ??
                        const CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.primary,
                          child: Icon(Icons.person_outline, size: 40),
                        ),
                  ),
                  const SizedBox(height: 16),
                  _dato('Nombre completo', u.nombreCompleto),
                  _dato('Correo electrónico', u.correo),
                  _dato('Identificador', '${u.id}'),
                  _dato('Rol', u.esAdministrador ? 'Administrador' : 'Usuario'),
                  _dato('Estado', u.estado ? 'Activa' : 'Inactiva'),
                  _dato('Fecha de registro', _fecha(u.fechaRegistro)),
                  if (!u.estado && u.tieneFoto)
                    const Text(
                      'La fotografía no está disponible mientras la cuenta está inactiva.',
                    ),
                  if (u.esAdministrador)
                    const Text('Las cuentas administrativas están protegidas.'),
                  if (!u.esAdministrador)
                    FilledButton.icon(
                      onPressed: _busy || _error != null ? null : _cambiar,
                      style: FilledButton.styleFrom(
                        backgroundColor: u.estado
                            ? AppColors.danger
                            : AppColors.primary,
                      ),
                      icon: Icon(
                        u.estado ? Icons.block : Icons.check_circle_outline,
                      ),
                      label: Text(
                        u.estado ? 'Desactivar cuenta' : 'Activar cuenta',
                      ),
                    ),
                ],
                if (_aviso != null) Text(_aviso!),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.errorText),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : _cargar,
            child: const Text('Actualizar'),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _fecha(DateTime fecha) {
    final local = fecha.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  Widget _dato(String etiqueta, String valor) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(color: AppColors.outline)),
        SelectableText(
          valor,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
