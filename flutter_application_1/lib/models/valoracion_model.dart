class ValoracionResumen {
  const ValoracionResumen({
    required this.blogId,
    required this.promedio,
    required this.total,
    required this.miPuntuacion,
  });

  final int blogId;
  final double? promedio;
  final int total;
  final int? miPuntuacion;

  factory ValoracionResumen.fromJson(Map<String, dynamic> json) =>
      ValoracionResumen(
        blogId: json['id_blog'] as int,
        promedio: (json['promedio'] as num?)?.toDouble(),
        total: json['total'] as int,
        miPuntuacion: json['mi_puntuacion'] as int?,
      );
}
