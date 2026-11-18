import 'json_model.dart';

class TipoReaccionModel {
  const TipoReaccionModel({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.estado,
  });

  final int id;
  final String nombre;
  final String emoji;
  final bool estado;

  factory TipoReaccionModel.fromJson(Map<String, dynamic> json) =>
      TipoReaccionModel(
        id: json['id_tipo_reaccion'] as int,
        nombre: json['nombre'] as String,
        emoji: json['emoji'] as String,
        estado: json['estado'] as bool,
      );
}

class ReaccionConteo {
  const ReaccionConteo({required this.tipoReaccion, required this.total});

  final TipoReaccionModel tipoReaccion;
  final int total;

  factory ReaccionConteo.fromJson(Map<String, dynamic> json) => ReaccionConteo(
    tipoReaccion: TipoReaccionModel.fromJson(jsonObject(json['tipo_reaccion'])),
    total: json['total'] as int,
  );
}

class ReaccionResumen {
  const ReaccionResumen({
    required this.comentarioId,
    required this.miReaccion,
    required this.resultados,
  });

  final int comentarioId;
  final int? miReaccion;
  final List<ReaccionConteo> resultados;

  factory ReaccionResumen.fromJson(Map<String, dynamic> json) =>
      ReaccionResumen(
        comentarioId: json['id_comentario'] as int,
        miReaccion: json['mi_reaccion'] as int?,
        resultados: jsonList(json['resultados'], ReaccionConteo.fromJson),
      );

  int get total => resultados.fold(0, (suma, item) => suma + item.total);
}
