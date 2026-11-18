import 'categoria_model.dart';
import 'json_model.dart';
import 'user_model.dart';

class PostModel {
  const PostModel({
    required this.id,
    required this.usuarioId,
    required this.categoriaId,
    required this.titulo,
    required this.descripcion,
    required this.contenido,
    required this.tipoImagen,
    required this.fechaPublicacion,
    required this.fechaActualizacion,
    required this.autor,
    required this.categoria,
  });

  final int id;
  final int usuarioId;
  final int categoriaId;
  final String titulo;
  final String descripcion;
  final String? contenido;
  final String? tipoImagen;
  final DateTime fechaPublicacion;
  final DateTime? fechaActualizacion;
  final UserSummary autor;
  final CategoriaModel categoria;

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
    id: json['id_blog'] as int,
    usuarioId: json['id_usuario'] as int,
    categoriaId: json['id_categoria'] as int,
    titulo: json['titulo'] as String,
    descripcion: json['descripcion'] as String,
    contenido: json['contenido'] as String?,
    tipoImagen: json['tipo_imagen'] as String?,
    fechaPublicacion: apiDate(json['fecha_publicacion'] as String),
    fechaActualizacion: json['fecha_actualizacion'] == null
        ? null
        : apiDate(json['fecha_actualizacion'] as String),
    autor: UserSummary.fromJson(jsonObject(json['autor'])),
    categoria: CategoriaModel.fromJson(jsonObject(json['categoria'])),
  );

  bool get tieneImagen => tipoImagen != null;
}
