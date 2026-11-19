import 'dart:typed_data';

import '../core/api_client.dart';
import '../models/json_model.dart';
import '../models/user_model.dart';

class AdminUserService {
  const AdminUserService(this.api);
  final ApiClient api;
  static const int pageSize = 50;

  Future<List<UserModel>> listar({int offset = 0}) async {
    final result = await api.json(
      'GET',
      '/usuarios/admin',
      query: {'offset': '$offset', 'limite': '$pageSize'},
    );
    return jsonList(result, UserModel.fromJson);
  }

  Future<List<UserModel>> listarTodos() async {
    final usuarios = <int, UserModel>{};
    var offset = 0;
    while (true) {
      final pagina = await listar(offset: offset);
      for (final usuario in pagina) {
        usuarios[usuario.id] = usuario;
      }
      if (pagina.length < pageSize) return usuarios.values.toList();
      offset += pagina.length;
    }
  }

  Future<UserModel> consultar(int id) async => UserModel.fromJson(
    jsonObject(await api.json('GET', '/usuarios/admin/$id')),
  );

  Future<UserModel> cambiarEstado(int id, bool estado) async =>
      UserModel.fromJson(
        jsonObject(
          await api.json(
            'PATCH',
            '/usuarios/admin/$id/estado',
            body: {'estado': estado},
          ),
        ),
      );

  Future<Uint8List> foto(int id) => api.bytes('/usuarios/$id/foto');
}
