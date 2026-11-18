class CategoriaModel {
  const CategoriaModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.estado,
  });

  final int id;
  final String nombre;
  final String? descripcion;
  final bool estado;

  factory CategoriaModel.fromJson(Map<String, dynamic> json) => CategoriaModel(
    id: json['id_categoria'] as int,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String?,
    estado: json['estado'] as bool,
  );
}
