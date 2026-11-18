import 'json_model.dart';

class UserSummary {
  const UserSummary({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.tipoImagen,
  });

  final int id;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String? tipoImagen;

  factory UserSummary.fromJson(Map<String, dynamic> json) => UserSummary(
    id: json['id_usuario'] as int,
    nombre: json['nombre'] as String,
    apellidoPaterno: json['apellido_paterno'] as String,
    apellidoMaterno: json['apellido_materno'] as String?,
    tipoImagen: json['tipo_imagen'] as String?,
  );

  String get nombreCompleto =>
      [nombre, apellidoPaterno, ?apellidoMaterno].join(' ');
  bool get tieneFoto => tipoImagen != null;
}

class UserModel {
  const UserModel({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.tipoImagen,
    required this.correo,
    required this.rol,
    required this.estado,
    required this.fechaRegistro,
  });

  final int id;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String? tipoImagen;
  final String correo;
  final String rol;
  final bool estado;
  final DateTime fechaRegistro;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id_usuario'] as int,
    nombre: json['nombre'] as String,
    apellidoPaterno: json['apellido_paterno'] as String,
    apellidoMaterno: json['apellido_materno'] as String?,
    tipoImagen: json['tipo_imagen'] as String?,
    correo: json['correo'] as String,
    rol: json['rol'] as String,
    estado: json['estado'] as bool,
    fechaRegistro: apiDate(json['fecha_registro'] as String),
  );

  bool get esAdministrador => rol == 'administrador';
  String get nombreCompleto =>
      [nombre, apellidoPaterno, ?apellidoMaterno].join(' ');
  bool get tieneFoto => tipoImagen != null;
}
