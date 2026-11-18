import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/session_storage.dart';
import '../models/auth_model.dart';
import '../models/json_model.dart';
import '../models/request_models.dart';
import '../models/user_model.dart';

class AuthService {
  const AuthService(this.api, {this.storage = const SessionStorage()});
  final ApiClient api;
  final SessionStorage storage;

  Future<UserModel> login(String correo, String contrasena) async {
    final body = RequestModels.login(correo, contrasena);
    if (kIsWeb) {
      final result = await api.json(
        'POST',
        '/auth/login',
        body: body,
        authenticated: false,
      );
      return LoginModel.fromJson(jsonObject(result)).usuario;
    }
    final result = await api.json(
      'POST',
      '/auth/token',
      body: body,
      authenticated: false,
    );
    final token = TokenModel.fromJson(jsonObject(result));
    if (token.tokenType != 'bearer' || token.accessToken.isEmpty) {
      throw const ApiException('Respuesta de autenticación inválida.');
    }
    await storage.save(token.accessToken);
    try {
      return await currentUser();
    } catch (_) {
      await storage.clear();
      rethrow;
    }
  }

  Future<UserModel> currentUser() async =>
      UserModel.fromJson(jsonObject(await api.json('GET', '/auth/me')));

  Future<UserModel?> restore() async {
    if (!kIsWeb && (await storage.read()) == null) {
      return null;
    }
    try {
      return await currentUser();
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }
      await storage.clear();
      return null;
    }
  }

  /// No informa éxito si el servidor no confirmó la revocación.
  Future<void> logout() async {
    try {
      await api.json('POST', '/auth/logout');
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }
    }
    await storage.clear();
  }
}
