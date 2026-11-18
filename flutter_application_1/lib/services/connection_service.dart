import '../core/api_client.dart';
import '../core/api_exception.dart';

class ConnectionService {
  const ConnectionService(this.api);
  final ApiClient api;

  /// Comprueba tanto la API como el acceso real a MySQL.
  Future<String> check() async {
    final info = await api.json('GET', '/', authenticated: false);
    final config = await api.json(
      'GET',
      '/configuracion',
      authenticated: false,
    );
    if (info is! Map ||
        info['version'] is! String ||
        config is! Map ||
        config['id_configuracion'] != 1 ||
        config['nombre_app'] is! String) {
      throw const ApiException('Respuesta de conexión inesperada.');
    }
    return '${config['nombre_app']} · API ${info['version']}';
  }
}
