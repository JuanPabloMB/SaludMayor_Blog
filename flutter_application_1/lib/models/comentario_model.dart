import 'json_model.dart';
import 'user_model.dart';

class ComentarioModel {
  const ComentarioModel({
    required this.id,
    required this.usuarioId,
    required this.blogId,
    required this.comentario,
    required this.fechaComentario,
    required this.usuario,
  });

  final int id;
  final int usuarioId;
  final int blogId;
  final String comentario;
  final DateTime fechaComentario;
  final UserSummary usuario;

  factory ComentarioModel.fromJson(Map<String, dynamic> json) =>
      ComentarioModel(
        id: json['id_comentario'] as int,
        usuarioId: json['id_usuario'] as int,
        blogId: json['id_blog'] as int,
        comentario: json['comentario'] as String,
        fechaComentario: apiDate(json['fecha_comentario'] as String),
        usuario: UserSummary.fromJson(jsonObject(json['usuario'])),
      );
}
