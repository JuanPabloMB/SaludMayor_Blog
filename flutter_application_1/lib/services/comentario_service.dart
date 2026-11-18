import '../core/api_client.dart';
import '../models/comentario_model.dart';
import '../models/json_model.dart';

/// Operaciones de lectura y creación de comentarios de una publicación.
class ComentarioService {
  const ComentarioService(this.api);

  final ApiClient api;

  Future<List<ComentarioModel>> obtenerComentarios(
    int idBlog, {
    int offset = 0,
    int limite = 50,
  }) async {
    final response = await api.json(
      'GET',
      '/blog/$idBlog/comentarios',
      query: {'offset': '$offset', 'limite': '$limite'},
    );
    return jsonList(response, ComentarioModel.fromJson);
  }

  Future<ComentarioModel> agregarComentario(
    int idBlog,
    String comentario,
  ) async {
    final response = await api.json(
      'POST',
      '/blog/$idBlog/comentarios',
      body: {'comentario': comentario.trim()},
    );
    return ComentarioModel.fromJson(jsonObject(response));
  }
}
