import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../widgets/admin_drawer.dart';

class AddBlogPage extends StatefulWidget {
  const AddBlogPage({super.key});

  @override
  State<AddBlogPage> createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  static const _urlBlog = 'http://127.0.0.1:8000/blog';

  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _tags = TextEditingController();
  final _picker = ImagePicker();

  XFile? _foto;
  Uint8List? _imagenBytes;
  bool _capturando = false;
  bool _guardando = false;
  Map<String, dynamic> _usuario = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _usuario = Map<String, dynamic>.from(args);
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    if (_capturando || _guardando) return;
    setState(() => _capturando = true);

    try {
      final foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );
      if (foto == null || !mounted) return;

      final bytes = await foto.readAsBytes();
      if (!mounted) return;

      if (bytes.isEmpty) {
        throw StateError('El archivo de imagen está vacío');
      }

      setState(() {
        _foto = foto;
        _imagenBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener la foto: $error')),
      );
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
  }

  Future<void> _guardar() async {
    if (_guardando || _capturando || !_formKey.currentState!.validate()) {
      return;
    }

    final foto = _foto;
    final bytes = _imagenBytes;
    if (foto == null || bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega una fotografía')),
      );
      return;
    }

    final tags = _tags.text.trim();
    setState(() => _guardando = true);

    try {
      final solicitud = http.MultipartRequest('POST', Uri.parse(_urlBlog))
        ..headers['Accept'] = 'application/json'
        ..fields['titulo'] = _titulo.text.trim()
        ..fields['descripcion'] = _descripcion.text.trim()
        ..files.add(
          http.MultipartFile.fromBytes(
            'imagen',
            bytes,
            filename: foto.name,
          ),
        );

      if (tags.isNotEmpty) {
        solicitud.fields['tags'] = tags;
      }

      final respuesta = await http.Response.fromStream(
        await solicitud.send(),
      );

      if (respuesta.statusCode != 201) {
        var mensaje = 'La API respondió con HTTP ${respuesta.statusCode}';
        try {
          final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
          if (datos is Map && datos['detail'] != null) {
            mensaje = datos['detail'].toString();
          }
        } on FormatException {
          // Conserva el mensaje HTTP si la respuesta no es JSON.
        }
        throw Exception(mensaje);
      }

      if (!mounted) return;
      _formKey.currentState!.reset();
      _titulo.clear();
      _descripcion.clear();
      _tags.clear();

      setState(() {
        _foto = null;
        _imagenBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación agregada correctamente')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar: '
            '${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _usuario['nom_usr']?.toString() ?? 'Administrador';
    final bytes = _imagenBytes;
    final ocupado = _capturando || _guardando;

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar blog')),
      drawer: AdminDrawer(usuario: _usuario, rutaActual: '/add-blog'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nueva publicación',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text('Administrador: $nombre'),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titulo,
                        enabled: !_guardando,
                        maxLength: 150,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) =>
                            (valor ?? '').trim().length < 2
                                ? 'Ingresa un título de al menos 2 caracteres'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descripcion,
                        enabled: !_guardando,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (valor) => (valor ?? '').trim().isEmpty
                            ? 'Ingresa la descripción'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: ocupado ? null : _tomarFoto,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(
                          _foto == null ? 'Tomar foto' : 'Cambiar foto',
                        ),
                      ),
                      if (bytes != null) ...[
                        const SizedBox(height: 12),
                        Image.memory(
                          bytes,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _tags,
                        enabled: !_guardando,
                        maxLength: 255,
                        decoration: const InputDecoration(
                          labelText: 'Etiquetas (opcional)',
                          hintText: 'flutter, tecnología, móvil',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: ocupado ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _guardando ? 'Guardando...' : 'Guardar publicación',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}