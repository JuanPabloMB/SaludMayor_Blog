import '../core/api_client.dart';
import '../models/comentario_model.dart';
import '../models/json_model.dart';

/// Operaciones de lectura, creación y eliminación de comentarios.
class ComentarioService {
  const ComentarioService(this.api);

  final ApiClient api;

  /// Obtiene los comentarios activos de una publicación.
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

  /// Registra un comentario asociado al usuario autenticado.
  Future<ComentarioModel> agregarComentario(
    int idBlog,
    String comentario,
  ) async {
    final texto = comentario.trim();

    if (texto.isEmpty) {
      throw ArgumentError('El comentario no puede estar vacío.');
    }

    final response = await api.json(
      'POST',
      '/blog/$idBlog/comentarios',
      body: {'comentario': texto},
    );

    return ComentarioModel.fromJson(jsonObject(response));
  }

  /// Elimina lógicamente un comentario mediante FastAPI.
  ///
  /// El backend comprueba si el usuario es propietario
  /// o administrador. La interfaz no sustituye esa validación.
  Future<void> eliminarComentario(int idBlog, int idComentario) async {
    if (idBlog < 1 || idComentario < 1) {
      throw ArgumentError('Los identificadores deben ser positivos.');
    }

    await api.json('DELETE', '/blog/$idBlog/comentarios/$idComentario');
  }
}
