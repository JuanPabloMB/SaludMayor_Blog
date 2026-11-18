class RespuestaMensaje {
  const RespuestaMensaje({required this.mensaje});

  final String mensaje;

  factory RespuestaMensaje.fromJson(Map<String, dynamic> json) =>
      RespuestaMensaje(mensaje: json['mensaje'] as String);
}
