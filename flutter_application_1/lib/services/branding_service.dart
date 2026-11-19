import 'dart:typed_data';

import '../core/api_client.dart';
import '../models/configuracion_model.dart';
import '../models/json_model.dart';

class BrandingService {
  const BrandingService(this.api);
  final ApiClient api;
  Future<ConfiguracionModel> load() async => ConfiguracionModel.fromJson(
    jsonObject(await api.json('GET', '/configuracion', authenticated: false)),
  );
  Future<Uint8List> logo() =>
      api.bytes('/configuracion/logotipo', authenticated: false);
  Future<ConfiguracionModel> rename(String name) async =>
      ConfiguracionModel.fromJson(
        jsonObject(
          await api.json('PATCH', '/configuracion', body: {'nombre_app': name}),
        ),
      );
  Future<ConfiguracionModel> upload(
    Uint8List bytes,
    String name,
    String mime,
  ) async => ConfiguracionModel.fromJson(
    jsonObject(
      await api.uploadFile(
        'PUT',
        '/configuracion/logotipo',
        bytes: bytes,
        fileName: name,
        mimeType: mime,
      ),
    ),
  );
  Future<ConfiguracionModel> remove() async => ConfiguracionModel.fromJson(
    jsonObject(await api.json('DELETE', '/configuracion/logotipo')),
  );
}
