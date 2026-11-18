import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/categoria_model.dart';
import '../models/post_model.dart';
import '../services/blog_service.dart';
import 'post_detail_page.dart';
import 'post_editor_page.dart';

/// Listado de publicaciones. La administración visual solo aparece para el administrador;
/// FastAPI vuelve a validar los permisos en cada operación de escritura.
class PublicationsPage extends StatefulWidget {
  const PublicationsPage({super.key, required this.api, required this.isAdmin});

  final ApiClient api;
  final bool isAdmin;

  @override
  State<PublicationsPage> createState() => _PublicationsPageState();
}

class _PublicationsPageState extends State<PublicationsPage> {
  late final BlogService _service = BlogService(widget.api);
  final TextEditingController _searchController = TextEditingController();

  List<PostModel> _posts = const [];
  List<CategoriaModel> _categories = const [];
  bool _loading = true;
  String? _error;
  int? _categoryId;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.obtenerPublicaciones(),
        _service.obtenerCategorias(),
      ]);
      if (!mounted) return;
      setState(() {
        _posts = results[0] as List<PostModel>;
        _categories = results[1] as List<CategoriaModel>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(error);
        _loading = false;
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('401')) {
      return 'Tu sesión ya no está disponible. Inicia sesión nuevamente.';
    }
    if (message.contains('403')) {
      return 'No tienes permisos para realizar esta operación.';
    }
    if (message.contains('servidor') || message.contains('comunicar')) {
      return 'No fue posible conectar con SaludMayor. Comprueba que el servidor esté activo.';
    }
    return 'No fue posible cargar las publicaciones. Inténtalo nuevamente.';
  }

  List<PostModel> get _filteredPosts {
    final query = _search.trim().toLowerCase();
    return _posts.where((post) {
      final matchesCategory =
          _categoryId == null || post.categoriaId == _categoryId;
      final matchesSearch =
          query.isEmpty ||
          post.titulo.toLowerCase().contains(query) ||
          post.descripcion.toLowerCase().contains(query) ||
          post.autor.nombreCompleto.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _openEditor({PostModel? post}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PostEditorPage(api: widget.api, post: post),
      ),
    );
    if (changed == true && mounted) {
      await _load();
      _showMessage(
        post == null
            ? 'La publicación se creó correctamente.'
            : 'La publicación se actualizó correctamente.',
      );
    }
  }

  Future<void> _deletePost(PostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text(
          '¿Estás seguro de eliminar "${post.titulo}"? Esta acción también eliminará sus comentarios y valoraciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.eliminar(post.id);
      if (!mounted) return;
      await _load();
      _showMessage('La publicación se eliminó correctamente.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_friendlyError(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: const Color(0xFFF8F7F0),
      child: RefreshIndicator(
        color: colors.primary,
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 230),
                  Center(child: CircularProgressIndicator()),
                  SizedBox(height: 230),
                ],
              )
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _load)
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final posts = _filteredPosts;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Publicaciones',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    if (widget.isAdmin)
                      FilledButton.icon(
                        onPressed: () => _openEditor(),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva publicación'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Consejos, experiencias e información para el bienestar del adulto mayor.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _search = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar publicaciones o autores',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFFFFDF7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Todas'),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                    ..._categories
                        .where((category) => category.estado)
                        .map(
                          (category) => FilterChip(
                            label: Text(category.nombre),
                            selected: _categoryId == category.id,
                            onSelected: (_) =>
                                setState(() => _categoryId = category.id),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      '${posts.length} ${posts.length == 1 ? 'publicación' : 'publicaciones'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Actualizar publicaciones',
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                if (posts.isEmpty)
                  const _EmptyState()
                else
                  ...posts.map(
                    (post) => _PostCard(
                      api: widget.api,
                      post: post,
                      isAdmin: widget.isAdmin,
                      imageFuture: post.tieneImagen
                          ? _service.obtenerImagen(post.id)
                          : null,
                      onEdit: () => _openEditor(post: post),
                      onDelete: () => _deletePost(post),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.api,
    required this.post,
    required this.isAdmin,
    required this.imageFuture,
    required this.onEdit,
    required this.onDelete,
  });

  final ApiClient api;
  final PostModel post;
  final bool isAdmin;
  final Future<Uint8List>? imageFuture;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFFFFDF7),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PostDetailPage(api: api, post: post),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageFuture != null)
                  FutureBuilder<Uint8List>(
                    future: imageFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          width: double.infinity,
                          height: 210,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                        );
                      }
                      if (snapshot.hasError) return const _ImagePlaceholder();
                      return const SizedBox(
                        height: 170,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            label: Text(post.categoria.nombre),
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                            _formatDate(post.fechaPublicacion),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(post.titulo, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(post.descripcion, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.account_circle_outlined, size: 20),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              post.autor.nombreCompleto,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const Icon(Icons.open_in_new, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            'Ver publicación',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    height: 170,
    width: double.infinity,
    color: const Color(0xFFE8EFE4),
    alignment: Alignment.center,
    child: const Icon(
      Icons.image_not_supported_outlined,
      size: 42,
      color: Color(0xFF55745E),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 70),
    child: Column(
      children: [
        Icon(Icons.article_outlined, size: 54, color: Color(0xFF55745E)),
        SizedBox(height: 12),
        Text('No hay publicaciones que coincidan con tu búsqueda.'),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 110),
      const Icon(Icons.cloud_off_outlined, size: 52, color: Color(0xFF55745E)),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(message, textAlign: TextAlign.center),
      ),
      const SizedBox(height: 16),
      Center(
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ),
    ],
  );
}
