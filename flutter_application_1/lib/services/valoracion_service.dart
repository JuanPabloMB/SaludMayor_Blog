import '../core/api_client.dart';
import '../models/json_model.dart';
import '../models/valoracion_model.dart';

/// Consulta y registro de la valoración del usuario para una publicación.
class ValoracionService {
  const ValoracionService(this.api);

  final ApiClient api;

  Future<ValoracionResumen> obtenerResumen(int idBlog) async {
    final response = await api.json('GET', '/blog/$idBlog/valoraciones');
    return ValoracionResumen.fromJson(jsonObject(response));
  }

  Future<ValoracionResumen> guardar(int idBlog, int puntuacion) async {
    if (puntuacion < 1 || puntuacion > 5) {
      throw ArgumentError.value(
        puntuacion,
        'puntuacion',
        'Debe estar entre 1 y 5.',
      );
    }
    final response = await api.json(
      'PUT',
      '/blog/$idBlog/valoraciones',
      body: {'puntuacion': puntuacion},
    );
    return ValoracionResumen.fromJson(jsonObject(response));
  }
}
