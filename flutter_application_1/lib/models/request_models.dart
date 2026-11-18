/// Los identificadores del autor y los roles se determinan en FastAPI.
abstract final class RequestModels {
  static Map<String, dynamic> login(String correo, String contrasena) => {
    'correo': correo.trim(),
    'contrasena': contrasena,
  };
  static Map<String, dynamic> registro({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String correo,
    required String contrasena,
  }) => {
    'nombre': nombre.trim(),
    'apellido_paterno': apellidoPaterno.trim(),
    'apellido_materno': apellidoMaterno?.trim(),
    'correo': correo.trim(),
    'contrasena': contrasena,
  };
  static Map<String, dynamic> publicacion({
    required int categoriaId,
    required String titulo,
    required String descripcion,
    required String contenido,
  }) => {
    'id_categoria': categoriaId,
    'titulo': titulo.trim(),
    'descripcion': descripcion.trim(),
    'contenido': contenido.trim(),
  };
  static Map<String, dynamic> comentario(String texto) => {
    'comentario': texto.trim(),
  };
  static Map<String, dynamic> valoracion(int puntuacion) => {
    'puntuacion': puntuacion,
  };
  static Map<String, dynamic> reaccion(int tipoId) => {
    'id_tipo_reaccion': tipoId,
  };
  static Map<String, dynamic> mensaje(int receptorId, String texto) => {
    'id_receptor': receptorId,
    'mensaje': texto.trim(),
  };
}
