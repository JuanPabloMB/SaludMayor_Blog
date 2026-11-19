import '../core/api_client.dart';
import '../models/categoria_model.dart';
import '../models/json_model.dart';

class AdminCategoryService {
  const AdminCategoryService(this.api);
  final ApiClient api;

  Future<List<CategoriaModel>> listar() async => jsonList(
    await api.json('GET', '/categorias/admin'),
    CategoriaModel.fromJson,
  );

  Future<CategoriaModel> guardar({
    int? id,
    required String nombre,
    required String descripcion,
  }) async => CategoriaModel.fromJson(
    jsonObject(
      await api.json(
        id == null ? 'POST' : 'PATCH',
        id == null ? '/categorias/admin' : '/categorias/admin/$id',
        body: {
          'nombre': nombre.trim(),
          'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
        },
      ),
    ),
  );

  Future<CategoriaModel> cambiarEstado(int id, bool estado) async =>
      CategoriaModel.fromJson(
        jsonObject(
          await api.json(
            'PATCH',
            '/categorias/admin/$id/estado',
            body: {'estado': estado},
          ),
        ),
      );
}
