import '../core/api_client.dart';
import '../models/json_model.dart';
import '../models/request_models.dart';
import '../models/user_model.dart';

class RegistrationService {
  const RegistrationService(this.api);
  final ApiClient api;

  Future<UserModel> register({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String correo,
    required String contrasena,
  }) async {
    final result = await api.json(
      'POST',
      '/usuarios/registro',
      authenticated: false,
      body: RequestModels.registro(
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
        correo: correo,
        contrasena: contrasena,
      ),
    );
    return UserModel.fromJson(jsonObject(result));
  }
}
