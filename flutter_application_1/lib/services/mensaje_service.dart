import '../core/api_client.dart';
import '../models/json_model.dart';
import '../models/mensaje_model.dart';
import '../models/user_model.dart';

/// Servicio para gestionar la mensajería privada de SaludMayor.
class MensajeService {
  const MensajeService(this.api);

  final ApiClient api;

  /// Obtiene las conversaciones del usuario autenticado.
  Future<List<ConversacionModel>> obtenerConversaciones({
    int offset = 0,
    int limite = 50,
  }) async {
    final response = await api.json(
      'GET',
      '/mensajes/conversaciones',
      query: {'offset': '$offset', 'limite': '$limite'},
    );

    return jsonList(response, ConversacionModel.fromJson);
  }

  /// Obtiene los mensajes intercambiados con otro usuario.
  Future<List<MensajeModel>> obtenerMensajes(
    int idUsuario, {
    int offset = 0,
    int limite = 50,
  }) async {
    if (idUsuario < 1) {
      throw ArgumentError('El identificador del usuario no es válido.');
    }

    final response = await api.json(
      'GET',
      '/mensajes',
      query: {
        'id_usuario': '$idUsuario',
        'bandeja': 'todos',
        'offset': '$offset',
        'limite': '$limite',
      },
    );

    return jsonList(response, MensajeModel.fromJson);
  }

  /// Obtiene el número de mensajes pendientes de lectura.
  Future<MensajesPendientes> obtenerNoLeidos() async {
    final response = await api.json('GET', '/mensajes/no-leidos');

    return MensajesPendientes.fromJson(jsonObject(response));
  }

  /// Obtiene los usuarios disponibles para iniciar conversaciones.
  Future<List<UserSummary>> obtenerDestinatarios({
    int offset = 0,
    int limite = 100,
  }) async {
    final response = await api.json(
      'GET',
      '/usuarios',
      query: {'offset': '$offset', 'limite': '$limite'},
    );

    return jsonList(response, UserSummary.fromJson);
  }

  /// Envía un mensaje al destinatario indicado.
  ///
  /// El backend determina el emisor mediante la sesión autenticada.
  Future<MensajeModel> enviarMensaje(int idReceptor, String mensaje) async {
    final texto = mensaje.trim();

    if (idReceptor < 1) {
      throw ArgumentError('El destinatario no es válido.');
    }

    if (texto.isEmpty) {
      throw ArgumentError('El mensaje no puede estar vacío.');
    }

    if (texto.length > 4000) {
      throw ArgumentError('El mensaje supera los 4000 caracteres.');
    }

    final response = await api.json(
      'POST',
      '/mensajes',
      body: {'id_receptor': idReceptor, 'mensaje': texto},
    );

    return MensajeModel.fromJson(jsonObject(response));
  }

  /// Marca como leído un mensaje recibido.
  Future<MensajeModel> marcarComoLeido(int idMensaje) async {
    if (idMensaje < 1) {
      throw ArgumentError('El identificador del mensaje no es válido.');
    }

    final response = await api.json('PUT', '/mensajes/$idMensaje/leido');

    return MensajeModel.fromJson(jsonObject(response));
  }
}
