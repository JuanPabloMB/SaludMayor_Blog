import 'dart:typed_data';

import '../core/api_client.dart';
import '../models/categoria_model.dart';
import '../models/json_model.dart';
import '../models/post_model.dart';

/// Operaciones de consulta y administración de publicaciones mediante FastAPI.
class BlogService {
  const BlogService(this.api);

  final ApiClient api;

  Future<List<PostModel>> obtenerPublicaciones() async {
    final response = await api.json('GET', '/blog');
    return jsonList(response, PostModel.fromJson);
  }

  Future<PostModel> obtenerDetalle(int idBlog) async {
    final response = await api.json('GET', '/blog/$idBlog');
    return PostModel.fromJson(jsonObject(response));
  }

  Future<List<CategoriaModel>> obtenerCategorias() async {
    final response = await api.json('GET', '/categorias');
    return jsonList(response, CategoriaModel.fromJson);
  }

  Future<Uint8List> obtenerImagen(int idBlog) =>
      api.bytes('/blog/$idBlog/imagen');

  Future<PostModel> crear({
    required int idCategoria,
    required String titulo,
    required String descripcion,
    required String contenido,
  }) async {
    final response = await api.json(
      'POST',
      '/blog',
      body: {
        'id_categoria': idCategoria,
        'titulo': titulo.trim(),
        'descripcion': descripcion.trim(),
        'contenido': contenido.trim(),
      },
    );
    return PostModel.fromJson(jsonObject(response));
  }

  Future<PostModel> actualizar(
    int idBlog, {
    required int idCategoria,
    required String titulo,
    required String descripcion,
    required String contenido,
  }) async {
    final response = await api.json(
      'PATCH',
      '/blog/$idBlog',
      body: {
        'id_categoria': idCategoria,
        'titulo': titulo.trim(),
        'descripcion': descripcion.trim(),
        'contenido': contenido.trim(),
      },
    );
    return PostModel.fromJson(jsonObject(response));
  }

  Future<void> eliminar(int idBlog) async {
    await api.json('DELETE', '/blog/$idBlog');
  }

  Future<void> subirImagen(
    int idBlog, {
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    await api.uploadFile(
      'PUT',
      '/blog/$idBlog/imagen',
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  Future<void> eliminarImagen(int idBlog) async {
    await api.json('DELETE', '/blog/$idBlog/imagen');
  }
}
