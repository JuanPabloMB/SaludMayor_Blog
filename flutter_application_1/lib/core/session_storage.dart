import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStorage {
  const SessionStorage();
  static const _key = 'saludmayor_access_token';
  static const _storage = FlutterSecureStorage();

  Future<String?> read() async =>
      kIsWeb ? null : await _storage.read(key: _key);
  Future<void> save(String token) async {
    if (!kIsWeb) {
      await _storage.write(key: _key, value: token);
    }
  }

  Future<void> clear() async {
    if (!kIsWeb) {
      await _storage.delete(key: _key);
    }
  }
}
