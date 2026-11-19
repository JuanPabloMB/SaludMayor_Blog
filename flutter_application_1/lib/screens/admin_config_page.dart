import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../models/configuracion_model.dart';
import '../services/branding_service.dart';
import '../widgets/blog_identity.dart';

class AdminConfigPage extends StatefulWidget {
  const AdminConfigPage({super.key, required this.api});
  final ApiClient api;
  @override
  State<AdminConfigPage> createState() => _AdminConfigPageState();
}

class _AdminConfigPageState extends State<AdminConfigPage> {
  late final BrandingService _service = BrandingService(widget.api);
  final _name = TextEditingController();
  ConfiguracionModel? _config;
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final config = await _service.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _config = config;
        _name.text = config.nombreApp;
      });
      await BlogIdentity.of(context)?.refresh();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo consultar la configuración: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _perform(Future<ConfiguracionModel?> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await action();
      if (!mounted || result == null) {
        return;
      }
      setState(() => _config = result);
      await BlogIdentity.of(context)?.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo completar la operación: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _rename() async {
    final name = _name.text.trim();
    if (name.isEmpty || name.runes.length > 100) {
      setState(() => _error = 'Escribe un nombre de 1 a 100 caracteres.');
      return;
    }
    await _perform(() => _service.rename(name));
  }

  Future<void> _pick() => _perform(() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) {
      return null;
    }
    final length = await file.length();
    if (length == 0 || length > 2 * 1024 * 1024) {
      throw const FormatException('Selecciona una imagen de hasta 2 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 2 * 1024 * 1024) {
      throw const FormatException('Tamaño de imagen inválido.');
    }
    final mime = switch (file.name.split('.').last.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
    if (mime == null) {
      throw const FormatException('Solo JPG, PNG y WEBP.');
    }
    if (!mounted) {
      return null;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vista previa del logotipo'),
        content: Image.memory(
          bytes,
          width: 220,
          height: 180,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) =>
              const Text('Imagen no válida'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) {
      return null;
    }
    return _service.upload(bytes, file.name, mime);
  });
  Future<void> _remove() => _perform(() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar logotipo'),
        content: const Text('Se mostrará el icono predeterminado del blog.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) {
      return null;
    }
    return _service.remove();
  });
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Configuración del blog',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar configuración'),
            ),
            if (_config != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _name,
                        enabled: !_busy,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del blog',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      FilledButton(
                        onPressed: _busy ? null : _rename,
                        child: const Text('Guardar nombre'),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Logotipo del blog'),
                      const SizedBox(height: 16),
                      const BlogLogo(size: 140),
                      const SizedBox(height: 16),
                      const Text('JPG, PNG o WEBP · Máximo 2 MB'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _pick,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Seleccionar logotipo'),
                          ),
                          if (_config!.tieneLogotipo)
                            TextButton.icon(
                              onPressed: _busy ? null : _remove,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Eliminar logotipo'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
