import 'json_model.dart';

class ConfiguracionModel {
  const ConfiguracionModel({
    required this.id,
    required this.nombreApp,
    required this.tipoImagen,
    required this.fechaActualizacion,
  });

  final int id;
  final String nombreApp;
  final String? tipoImagen;
  final DateTime fechaActualizacion;

  factory ConfiguracionModel.fromJson(Map<String, dynamic> json) =>
      ConfiguracionModel(
        id: json['id_configuracion'] as int,
        nombreApp: json['nombre_app'] as String,
        tipoImagen: json['tipo_imagen'] as String?,
        fechaActualizacion: apiDate(json['fecha_actualizacion'] as String),
      );

  bool get tieneLogotipo => tipoImagen != null;
}
