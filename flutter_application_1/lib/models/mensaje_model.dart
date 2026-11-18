import 'json_model.dart';
import 'user_model.dart';

class MensajeModel {
  const MensajeModel({
    required this.id,
    required this.emisorId,
    required this.receptorId,
    required this.mensaje,
    required this.fechaEnvio,
    required this.leido,
    required this.fechaLectura,
    required this.emisor,
    required this.receptor,
  });

  final int id;
  final int emisorId;
  final int receptorId;
  final String mensaje;
  final DateTime fechaEnvio;
  final bool leido;
  final DateTime? fechaLectura;
  final UserSummary emisor;
  final UserSummary receptor;

  factory MensajeModel.fromJson(Map<String, dynamic> json) => MensajeModel(
    id: json['id_mensaje'] as int,
    emisorId: json['id_emisor'] as int,
    receptorId: json['id_receptor'] as int,
    mensaje: json['mensaje'] as String,
    fechaEnvio: apiDate(json['fecha_envio'] as String),
    leido: json['leido'] as bool,
    fechaLectura: json['fecha_lectura'] == null
        ? null
        : apiDate(json['fecha_lectura'] as String),
    emisor: UserSummary.fromJson(jsonObject(json['emisor'])),
    receptor: UserSummary.fromJson(jsonObject(json['receptor'])),
  );
}

class ConversacionModel {
  const ConversacionModel({
    required this.usuario,
    required this.ultimoMensaje,
    required this.noLeidos,
  });

  final UserSummary usuario;
  final MensajeModel ultimoMensaje;
  final int noLeidos;

  factory ConversacionModel.fromJson(Map<String, dynamic> json) =>
      ConversacionModel(
        usuario: UserSummary.fromJson(jsonObject(json['usuario'])),
        ultimoMensaje: MensajeModel.fromJson(
          jsonObject(json['ultimo_mensaje']),
        ),
        noLeidos: json['no_leidos'] as int,
      );
}

class MensajesPendientes {
  const MensajesPendientes({required this.total});

  final int total;

  factory MensajesPendientes.fromJson(Map<String, dynamic> json) =>
      MensajesPendientes(total: json['total'] as int);
}
