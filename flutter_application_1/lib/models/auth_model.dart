import 'json_model.dart';
import 'user_model.dart';

class LoginModel {
  const LoginModel({required this.usuario, required this.fechaExpiracion});

  final UserModel usuario;
  final DateTime fechaExpiracion;

  factory LoginModel.fromJson(Map<String, dynamic> json) => LoginModel(
    usuario: UserModel.fromJson(jsonObject(json['usuario'])),
    fechaExpiracion: apiDate(json['fecha_expiracion'] as String),
  );
}

class TokenModel {
  const TokenModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  final String accessToken;
  final String tokenType;
  final int expiresIn;

  factory TokenModel.fromJson(Map<String, dynamic> json) => TokenModel(
    accessToken: json['access_token'] as String,
    tokenType: json['token_type'] as String,
    expiresIn: json['expires_in'] as int,
  );
}
