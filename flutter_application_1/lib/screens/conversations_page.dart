import 'package:flutter/material.dart';

import '../models/mensaje_model.dart';
import '../models/user_model.dart';
import '../services/mensaje_service.dart';
import '../theme/app_colors.dart';
import 'chat_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({
    super.key,
    required this.user,
    required this.service,
    this.onMessagesReturned,
  });

  final UserModel user;
  final MensajeService service;
  final VoidCallback? onMessagesReturned;

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  List<ConversacionModel> _conversaciones = [];

  bool _loading = true;
  bool _loadingDestinatarios = false;
  String? _error;

  int get _totalNoLeidos => _conversaciones.fold(
    0,
    (total, conversacion) => total + conversacion.noLeidos,
  );

  @override
  void initState() {
    super.initState();
    _cargarConversaciones();
  }

  Future<void> _cargarConversaciones() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final resultado = await widget.service.obtenerConversaciones();

      if (!mounted) return;

      setState(() {
        _conversaciones = resultado;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _abrirChat(UserSummary usuario) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(
          user: widget.user,
          contact: usuario,
          service: widget.service,
        ),
      ),
    );

    if (!mounted) return;

    await _cargarConversaciones();

    if (!mounted) return;

    widget.onMessagesReturned?.call();
  }

  Future<void> _nuevoMensaje() async {
    if (_loadingDestinatarios) return;

    setState(() => _loadingDestinatarios = true);

    try {
      final usuarios = await widget.service.obtenerDestinatarios();

      if (!mounted) return;

      setState(() => _loadingDestinatarios = false);

      final disponibles = usuarios
          .where((usuario) => usuario.id != widget.user.id)
          .toList();

      if (disponibles.isEmpty) {
        _mostrarAviso('No hay otros usuarios disponibles.');
        return;
      }

      final seleccionado = await showDialog<UserSummary>(
        context: context,
        builder: (dialogContext) {
          return _SelectorDestinatario(usuarios: disponibles);
        },
      );

      if (seleccionado == null || !mounted) return;

      await _abrirChat(seleccionado);
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingDestinatarios = false);

      _mostrarAviso('No se pudieron consultar los usuarios: $e');
    }
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  String _fecha(DateTime fecha) {
    final local = fecha.toLocal();
    final ahora = DateTime.now();

    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final diaMensaje = DateTime(local.year, local.month, local.day);

    if (diaMensaje == hoy) {
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }

    if (diaMensaje == hoy.subtract(const Duration(days: 1))) {
      return 'Ayer';
    }

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _vistaPrevia(MensajeModel mensaje) {
    final esPropio = mensaje.emisorId == widget.user.id;

    return esPropio ? 'Tú: ${mensaje.mensaje}' : mensaje.mensaje;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
                  child: RefreshIndicator(
                    onRefresh: _cargarConversaciones,
                    color: AppColors.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _encabezado(theme),
                        const SizedBox(height: 24),
                        _contenido(),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  left: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    onPressed: _loadingDestinatarios ? null : _nuevoMensaje,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    icon: _loadingDestinatarios
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.edit_outlined),
                    label: const Text('Nuevo mensaje'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _encabezado(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE9D9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.forum_outlined,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mensajes',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tus conversaciones privadas',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Actualizar conversaciones',
              onPressed: _loading ? null : _cargarConversaciones,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCE3D5)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.mark_chat_unread_outlined,
                color: AppColors.primary,
                size: 25,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mensajes sin leer',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 30),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _totalNoLeidos > 0
                      ? AppColors.primary
                      : const Color(0xFFE8EFE4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_totalNoLeidos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _totalNoLeidos > 0 ? Colors.white : AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contenido() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _estadoError();
    }

    if (_conversaciones.isEmpty) {
      return _estadoVacio();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _conversaciones.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _tarjetaConversacion(_conversaciones[index]);
      },
    );
  }

  Widget _tarjetaConversacion(ConversacionModel conversacion) {
    final usuario = conversacion.usuario;
    final ultimo = conversacion.ultimoMensaje;
    final noLeidos = conversacion.noLeidos;
    final theme = Theme.of(context);

    return Card(
      color: AppColors.surface,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: noLeidos > 0
              ? const Color(0xFFB7C9B5)
              : const Color(0xFFE8E8DF),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirChat(usuario),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: const Color(0xFFDCE9D9),
                child: Text(
                  usuario.nombre.isNotEmpty
                      ? usuario.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombreCompleto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: noLeidos > 0
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _vistaPrevia(ultimo),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: noLeidos > 0 ? AppColors.text : Colors.black54,
                        fontWeight: noLeidos > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fecha(ultimo.fechaEnvio),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 9),
                  if (noLeidos > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$noLeidos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 65,
              color: Color(0xFF78927B),
            ),
            const SizedBox(height: 18),
            Text(
              'Todavía no tienes conversaciones',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Puedes iniciar una nueva conversación '
              'con otro usuario registrado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 55,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se pudieron cargar las conversaciones.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _cargarConversaciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorDestinatario extends StatefulWidget {
  const _SelectorDestinatario({required this.usuarios});

  final List<UserSummary> usuarios;

  @override
  State<_SelectorDestinatario> createState() => _SelectorDestinatarioState();
}

class _SelectorDestinatarioState extends State<_SelectorDestinatario> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  List<UserSummary> get _filtrados {
    final query = _query.trim().toLowerCase();

    if (query.isEmpty) return widget.usuarios;

    return widget.usuarios.where((usuario) {
      return usuario.nombreCompleto.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = _filtrados;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: const Color(0xFFFFFDF7),
      title: const Text(
        'Nuevo mensaje',
        style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar usuario...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _query = value);
                },
              ),
              const SizedBox(height: 12),
              if (usuarios.isEmpty)
                const Center(child: Text('No se encontraron usuarios.'))
              else
                for (final usuario in usuarios)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFDCE9D9),
                      foregroundColor: AppColors.primary,
                      child: Text(
                        usuario.nombre.isNotEmpty
                            ? usuario.nombre[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(
                      usuario.nombreCompleto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                    ),
                    onTap: () {
                      Navigator.pop(context, usuario);
                    },
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
