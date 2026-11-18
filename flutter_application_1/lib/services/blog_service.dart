import 'dart:typed_data';

import '../core/api_client.dart';
import '../models/categoria_model.dart';
import '../models/json_model.dart';
import '../models/post_model.dart';

/// Acceso a las publicaciones y categorías mediante la API de SaludMayor.
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
}
