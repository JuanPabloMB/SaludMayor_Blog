import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/comentario_model.dart';
import '../models/post_model.dart';
import '../models/valoracion_model.dart';
import '../services/blog_service.dart';
import '../services/comentario_service.dart';
import '../services/valoracion_service.dart';

/// Detalle de una publicación con comentarios y valoración integrada.
class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.api, required this.post});

  final ApiClient api;
  final PostModel post;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late final BlogService _blogService = BlogService(widget.api);
  late final ComentarioService _comentarioService = ComentarioService(
    widget.api,
  );
  late final ValoracionService _valoracionService = ValoracionService(
    widget.api,
  );

  final TextEditingController _commentController = TextEditingController();
  late PostModel _post = widget.post;
  List<ComentarioModel> _comments = const [];
  ValoracionResumen? _rating;
  bool _loading = true;
  bool _sendingComment = false;
  bool _savingRating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        _blogService.obtenerDetalle(widget.post.id),
        _comentarioService.obtenerComentarios(widget.post.id),
        _valoracionService.obtenerResumen(widget.post.id),
      ]);
      if (!mounted) return;
      setState(() {
        _post = results[0] as PostModel;
        _comments = results[1] as List<ComentarioModel>;
        _rating = results[2] as ValoracionResumen;
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
    if (message.contains('404')) {
      return 'Esta publicación ya no está disponible.';
    }
    if (message.contains('servidor') || message.contains('comunicar')) {
      return 'No fue posible conectar con SaludMayor. Comprueba que el servidor esté activo.';
    }
    return 'No fue posible cargar toda la información. Inténtalo nuevamente.';
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sendingComment) return;
    if (text.length > 4000) {
      _showMessage('El comentario no puede superar los 4000 caracteres.');
      return;
    }
    setState(() => _sendingComment = true);
    try {
      final comment = await _comentarioService.agregarComentario(
        _post.id,
        text,
      );
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, comment];
        _commentController.clear();
        _sendingComment = false;
      });
      _showMessage('Tu comentario se publicó correctamente.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _sendingComment = false);
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _saveRating(int score) async {
    if (_savingRating) return;
    setState(() => _savingRating = true);
    try {
      final rating = await _valoracionService.guardar(_post.id, score);
      if (!mounted) return;
      setState(() {
        _rating = rating;
        _savingRating = false;
      });
      _showMessage('Tu valoración se guardó correctamente.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _savingRating = false);
      _showMessage(_friendlyError(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F0),
      appBar: AppBar(
        title: const Text('Detalle de publicación'),
        backgroundColor: const Color(0xFFF5F3E8),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(message: _error!, onRetry: _load)
          : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF24563E),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_post.tieneImagen)
                    _PostImage(service: _blogService, id: _post.id),
                  const SizedBox(height: 18),
                  Chip(
                    avatar: const Icon(Icons.category_outlined, size: 18),
                    label: Text(_post.categoria.nombre),
                    backgroundColor: const Color(0xFFE3EBDD),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _post.titulo,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF24563E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AuthorLine(post: _post),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Acerca de esta publicación',
                    icon: Icons.article_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _post.descripcion,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if ((_post.contenido ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SelectableText(
                            _post.contenido!,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(height: 1.6),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRatingSection(),
                  const SizedBox(height: 16),
                  _buildCommentsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    final rating = _rating;
    return _SectionCard(
      title: 'Valoración',
      icon: Icons.star_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rating?.promedio?.toStringAsFixed(1) ?? '—',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF24563E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.star, color: Color(0xFFB58A35)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${rating?.total ?? 0} ${rating?.total == 1 ? 'valoración' : 'valoraciones'}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('¿Qué te pareció esta publicación?'),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              for (var score = 1; score <= 5; score++)
                IconButton(
                  tooltip:
                      'Calificar con $score ${score == 1 ? 'estrella' : 'estrellas'}',
                  onPressed: _savingRating ? null : () => _saveRating(score),
                  icon: Icon(
                    score <= (rating?.miPuntuacion ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: const Color(0xFFB58A35),
                    size: 32,
                  ),
                ),
              if (_savingRating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (rating?.miPuntuacion != null)
            Text('Tu puntuación actual: ${rating!.miPuntuacion} de 5'),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return _SectionCard(
      title: 'Comentarios (${_comments.length})',
      icon: Icons.forum_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Todavía no hay comentarios. ¡Sé el primero en participar!',
              ),
            )
          else
            ..._comments.map((comment) => _CommentTile(comment: comment)),
          const Divider(height: 28),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 5,
            maxLength: 4000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Escribe un comentario',
              hintText: 'Comparte tu opinión de manera respetuosa...',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Color(0xFFF8F7F0),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _sendingComment ? null : _sendComment,
              icon: _sendingComment
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Publicar comentario'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.service, required this.id});

  final BlogService service;
  final int id;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: service.obtenerImagen(id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(
              snapshot.data!,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ImageFallback(),
            ),
          );
        }
        if (snapshot.hasError) return const _ImageFallback();
        return const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFFE8EFE4),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Icon(
      Icons.image_not_supported_outlined,
      size: 48,
      color: Color(0xFF55745E),
    ),
  );
}

class _AuthorLine extends StatelessWidget {
  const _AuthorLine({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final date = post.fechaPublicacion.toLocal();
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(
          Icons.account_circle_outlined,
          size: 20,
          color: Color(0xFF55745E),
        ),
        Text(post.autor.nombreCompleto),
        const Icon(
          Icons.calendar_today_outlined,
          size: 16,
          color: Color(0xFF55745E),
        ),
        Text(formatted, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFFDF7),
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF24563E)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF24563E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final ComentarioModel comment;

  @override
  Widget build(BuildContext context) {
    final date = comment.fechaComentario.toLocal();
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE3EBDD),
            foregroundColor: Color(0xFF24563E),
            child: Icon(Icons.person_outline),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.usuario.nombreCompleto,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(comment.comentario),
                const SizedBox(height: 4),
                Text(
                  formatted,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF68786A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Color(0xFF55745E),
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
