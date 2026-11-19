import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/categoria_model.dart';
import '../services/admin_category_service.dart';
import '../theme/app_colors.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key, required this.api});
  final ApiClient api;

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  late final _service = AdminCategoryService(widget.api);
  final _search = TextEditingController();
  List<CategoriaModel> _items = [];
  String _filter = 'todos';
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final items = await _service.listar();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo cargar el catálogo: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit([CategoriaModel? item]) async {
    if (_busy) return;
    final data = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _CategoryDialog(item: item),
    );
    if (!mounted || data == null) return;
    await _mutate(
      () =>
          _service.guardar(id: item?.id, nombre: data.$1, descripcion: data.$2),
      'Categoría guardada correctamente.',
    );
  }

  Future<void> _toggle(CategoriaModel item) async {
    if (_busy) return;
    final action = item.estado ? 'Desactivar' : 'Activar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action categoría'),
        content: Text(
          item.estado
              ? '¿Desactivar ${item.nombre}? Las publicaciones existentes se conservarán, pero la categoría no estará disponible para nuevas publicaciones.'
              : '¿Activar ${item.nombre}? Volverá a estar disponible para las publicaciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _mutate(
      () => _service.cambiarEstado(item.id, !item.estado),
      'Estado actualizado.',
    );
  }

  Future<void> _mutate(
    Future<CategoriaModel> Function() operation,
    String message,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final saved = await operation();
      if (!mounted) return;
      setState(() {
        _items = [..._items.where((item) => item.id != saved.id), saved]
          ..sort(
            (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
          );
      });
      _message(message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo guardar: $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _normalize(String value) {
    var result = value.toLowerCase();
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
    };
    accents.forEach(
      (key, replacement) => result = result.replaceAll(key, replacement),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final query = _normalize(_search.text.trim());
    final visible = _items
        .where(
          (item) =>
              (_filter == 'todos' || item.estado == (_filter == 'activas')) &&
              _normalize('${item.nombre} ${item.descripcion ?? ''} ${item.id}')
                  .contains(query),
        )
        .toList();
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Categorías',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('Administra la clasificación de las publicaciones.'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _edit(),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva categoría'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Buscar categoría',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _filter,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todas')),
                    DropdownMenuItem(value: 'activas', child: Text('Activas')),
                    DropdownMenuItem(
                      value: 'inactivas',
                      child: Text('Inactivas'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _filter = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text('${visible.length} de ${_items.length} categorías'),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.errorText),
                    ),
                  ),
                if (visible.isEmpty)
                  Center(
                    child: Text(
                      _busy ? 'Cargando...' : 'No hay categorías para mostrar.',
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      return Card(
                        color: AppColors.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nombre,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(item.descripcion ?? 'Sin descripción'),
                              Text(
                                'ID: ${item.id} · ${item.estado ? 'Activa' : 'Inactiva'}',
                                style: TextStyle(
                                  color: item.estado
                                      ? AppColors.successText
                                      : AppColors.errorText,
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton.icon(
                                    onPressed: _busy ? null : () => _edit(item),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Editar'),
                                  ),
                                  TextButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _toggle(item),
                                    icon: Icon(
                                      item.estado
                                          ? Icons.block
                                          : Icons.check_circle_outline,
                                    ),
                                    label: Text(
                                      item.estado ? 'Desactivar' : 'Activar',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.item});
  final CategoriaModel? item;
  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.nombre ?? '');
  late final _description = TextEditingController(
    text: widget.item?.descripcion ?? '',
  );
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    title: Text(widget.item == null ? 'Nueva categoría' : 'Editar categoría'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe un nombre.'
                    : null,
              ),
              TextFormField(
                controller: _description,
                maxLength: 255,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, (
              _name.text.trim(),
              _description.text.trim(),
            ));
          }
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}
