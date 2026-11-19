import '../core/api_client.dart';
import '../models/json_model.dart';
import '../models/reaccion_model.dart';

class ReaccionService {
  const ReaccionService(this.api);
  final ApiClient api;

  Future<ReaccionResumen> consultar(int id) => _solicitar('GET', id);

  Future<ReaccionResumen> guardar(int id, int tipo) =>
      _solicitar('PUT', id, body: {'id_tipo_reaccion': tipo});

  Future<ReaccionResumen> eliminar(int id) => _solicitar('DELETE', id);

  Future<ReaccionResumen> _solicitar(
    String metodo,
    int id, {
    Map<String, dynamic>? body,
  }) async {
    final respuesta = await api.json(
      metodo,
      '/comentarios/$id/reacciones',
      body: body,
    );
    return ReaccionResumen.fromJson(jsonObject(respuesta));
  }
}
