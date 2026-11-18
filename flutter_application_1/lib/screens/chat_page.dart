import 'package:flutter/material.dart';

import '../models/mensaje_model.dart';
import '../models/user_model.dart';
import '../services/mensaje_service.dart';
import '../theme/app_colors.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.user,
    required this.contact,
    required this.service,
  });

  final UserModel user;
  final UserSummary contact;
  final MensajeService service;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MensajeModel> _messages = [];

  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await widget.service.obtenerMensajes(
        widget.contact.id,
        limite: 100,
      );

      final ordered = [...messages]
        ..sort((a, b) => a.fechaEnvio.compareTo(b.fechaEnvio));

      for (var i = 0; i < ordered.length; i++) {
        final message = ordered[i];

        if (message.receptorId == widget.user.id && !message.leido) {
          try {
            ordered[i] = await widget.service.marcarComoLeido(message.id);
          } catch (_) {
            // El mensaje permanece visible aunque falle la confirmación.
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _messages = ordered;
        _loading = false;
        _error = null;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _sending) return;

    if (text.length > 4000) {
      _showMessage('El mensaje no puede superar los 4000 caracteres.');
      return;
    }

    setState(() => _sending = true);

    try {
      final message = await widget.service.enviarMensaje(
        widget.contact.id,
        text,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(message);
        _controller.clear();
        _sending = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() => _sending = false);
      _showMessage('No se pudo enviar el mensaje: $e');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _time(DateTime date) {
    final local = date.toLocal();

    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _date(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3E8),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFDCE9D9),
              foregroundColor: AppColors.primary,
              child: Text(
                widget.contact.nombre.isNotEmpty
                    ? widget.contact.nombre[0].toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.nombreCompleto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const Text(
                    'Conversación privada',
                    style: TextStyle(fontSize: 12, color: AppColors.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar mensajes',
            onPressed: _loading ? null : _loadMessages,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessages()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 50,
                color: AppColors.outline,
              ),
              const SizedBox(height: 12),
              const Text(
                'No se pudieron cargar los mensajes.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadMessages,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, size: 55, color: Color(0xFF78927B)),
              SizedBox(height: 12),
              Text(
                'Inicia la conversación',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Envía el primer mensaje a este usuario.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadMessages,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];

          final showDate =
              index == 0 ||
              !_sameDay(message.fechaEnvio, _messages[index - 1].fechaEnvio);

          return Column(
            children: [
              if (showDate) _dateSeparator(message.fechaEnvio),
              _messageBubble(message),
            ],
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime first, DateTime second) {
    final a = first.toLocal();
    final b = second.toLocal();

    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _dateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EFE4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _date(date),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _messageBubble(MensajeModel message) {
    final own = message.emisorId == widget.user.id;

    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: own ? const Color(0xFFDCE9D9) : const Color(0xFFFFFDF7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(own ? 16 : 4),
            bottomRight: Radius.circular(own ? 4 : 16),
          ),
          border: Border.all(
            color: own ? const Color(0xFFB7C9B5) : const Color(0xFFE6E5DC),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                message.mensaje,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _time(message.fechaEnvio),
                  style: const TextStyle(
                    color: AppColors.outline,
                    fontSize: 11,
                  ),
                ),
                if (own) ...[
                  const SizedBox(width: 5),
                  Icon(
                    message.leido ? Icons.done_all : Icons.done,
                    size: 15,
                    color: message.leido
                        ? AppColors.successText
                        : AppColors.outline,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF7),
        border: Border(top: BorderSide(color: Color(0xFFE1E4D9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 4000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                counterText: '',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            height: 48,
            width: 48,
            child: FilledButton(
              onPressed: _sending ? null : _sendMessage,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}
