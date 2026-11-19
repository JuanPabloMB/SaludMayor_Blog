import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../models/categoria_model.dart';
import '../models/post_model.dart';
import '../services/blog_service.dart';

/// Formulario administrativo para crear o editar una publicación.
class PostEditorPage extends StatefulWidget {
  const PostEditorPage({super.key, required this.api, this.post});

  final ApiClient api;
  final PostModel? post;

  @override
  State<PostEditorPage> createState() => _PostEditorPageState();
}

class _PostEditorPageState extends State<PostEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _picker = ImagePicker();

  late final BlogService _service = BlogService(widget.api);
  List<CategoriaModel> _categories = const [];
  int? _categoryId;
  Uint8List? _selectedImage;
  String? _selectedImageName;
  String? _selectedImageMime;
  Future<Uint8List>? _existingImageFuture;
  bool _loading = true;
  bool _saving = false;
  bool _removeExistingImage = false;
  String? _loadError;

  bool get _editing => widget.post != null;
  bool get _hasExistingImage =>
      widget.post?.tieneImagen == true && !_removeExistingImage;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    try {
      final categories = await _service.obtenerCategorias();
      PostModel? detail;
      if (widget.post != null) {
        detail = await _service.obtenerDetalle(widget.post!.id);
      }
      if (!mounted) return;
      setState(() {
        _categories = categories;
        if (detail != null) {
          _titleController.text = detail.titulo;
          _descriptionController.text = detail.descripcion;
          _contentController.text = detail.contenido ?? '';
          final currentCategoryId = detail.categoriaId;
          _categoryId = categories.any((c) => c.id == currentCategoryId)
              ? currentCategoryId
              : null;
          if (detail.tieneImagen) {
            _existingImageFuture = _service.obtenerImagen(detail.id);
          }
        }
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _friendlyError(error);
        _loading = false;
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('401') || message.contains('403')) {
      return 'No tienes permisos para realizar esta operación. Verifica tu sesión de administrador.';
    }
    if (message.contains('servidor') || message.contains('comunicar')) {
      return 'No fue posible conectar con SaludMayor. Comprueba que FastAPI esté activo.';
    }
    return 'No fue posible cargar o guardar la información. $message';
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        _showMessage('El archivo seleccionado está vacío.');
        return;
      }
      if (bytes.length > 5 * 1024 * 1024) {
        _showMessage('La imagen no debe superar los 5 MB.');
        return;
      }
      final extension = file.name.split('.').last.toLowerCase();
      final mime = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => null,
      };
      if (mime == null) {
        _showMessage('Selecciona una imagen JPG, PNG o WEBP.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _selectedImage = bytes;
        _selectedImageName = file.name;
        _selectedImageMime = mime;
        _removeExistingImage = false;
      });
    } catch (error) {
      _showMessage('No fue posible seleccionar la imagen: $error');
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final categoryId = _categoryId;
    if (categoryId == null) {
      _showMessage('Selecciona una categoría.');
      return;
    }

    setState(() => _saving = true);
    try {
      final PostModel saved;
      if (_editing) {
        saved = await _service.actualizar(
          widget.post!.id,
          idCategoria: categoryId,
          titulo: _titleController.text,
          descripcion: _descriptionController.text,
          contenido: _contentController.text,
        );
      } else {
        saved = await _service.crear(
          idCategoria: categoryId,
          titulo: _titleController.text,
          descripcion: _descriptionController.text,
          contenido: _contentController.text,
        );
      }

      if (_selectedImage != null) {
        try {
          await _service.subirImagen(
            saved.id,
            bytes: _selectedImage!,
            fileName: _selectedImageName!,
            mimeType: _selectedImageMime!,
          );
        } catch (_) {
          if (!mounted) return;
          if (!_editing) {
            Navigator.of(context).pop(true);
            return;
          }
          rethrow;
        }
      } else if (_editing && _removeExistingImage) {
        await _service.eliminarImagen(saved.id);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(_friendlyError(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _imagePreview() {
    if (_selectedImage != null) {
      return Image.memory(
        _selectedImage!,
        height: 210,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    if (_hasExistingImage && _existingImageFuture != null) {
      return FutureBuilder<Uint8List>(
        future: _existingImageFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              height: 210,
              width: double.infinity,
              fit: BoxFit.cover,
            );
          }
          if (snapshot.hasError) {
            return const _ImagePlaceholder();
          }
          return const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        },
      );
    }
    return const _ImagePlaceholder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F0),
      appBar: AppBar(
        title: Text(_editing ? 'Editar publicación' : 'Nueva publicación'),
        backgroundColor: const Color(0xFFF5F3E8),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _LoadError(message: _loadError!, onRetry: _loadForm)
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Card(
                color: const Color(0xFFFFFDF7),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _editing
                            ? 'Actualizar contenido'
                            : 'Información de la publicación',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF24563E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titleController,
                        maxLength: 150,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          hintText: 'Escribe el título de la publicación',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'El título es obligatorio.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLength: 500,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción breve',
                          hintText: 'Resume de qué trata la publicación',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'La descripción es obligatoria.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      if (_editing && _categoryId == null)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Selecciona una categoría activa para guardar esta publicación.',
                          ),
                        ),
                      DropdownButtonFormField<int>(
                        initialValue: _categoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem<int>(
                                value: category.id,
                                child: Text(category.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _categoryId = value),
                        validator: (value) =>
                            value == null ? 'Selecciona una categoría.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contentController,
                        maxLength: 50000,
                        minLines: 8,
                        maxLines: 16,
                        decoration: const InputDecoration(
                          labelText: 'Contenido completo',
                          hintText:
                              'Desarrolla el contenido de la publicación...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'El contenido es obligatorio.'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Imagen de la publicación',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _imagePreview(),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _pickImage,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(
                              _selectedImage == null
                                  ? 'Seleccionar imagen'
                                  : 'Cambiar imagen',
                            ),
                          ),
                          if (_selectedImage != null || _hasExistingImage)
                            TextButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedImage = null;
                                        _selectedImageName = null;
                                        _selectedImageMime = null;
                                        _removeExistingImage =
                                            _editing &&
                                            widget.post!.tieneImagen;
                                      });
                                    },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Quitar imagen'),
                            ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Formatos permitidos: JPG, PNG y WEBP. Tamaño máximo: 5 MB.',
                          style: TextStyle(
                            color: Color(0xFF68786A),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _saving
                              ? 'Guardando...'
                              : _editing
                              ? 'Guardar cambios'
                              : 'Publicar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
      Icons.add_photo_alternate_outlined,
      size: 44,
      color: Color(0xFF55745E),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
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
