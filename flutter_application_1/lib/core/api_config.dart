import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const timeout = Duration(seconds: 15);
  static const _override = String.fromEnvironment('API_BASE_URL');

  static Uri get baseUri {
    final uri = Uri.parse(
      _override.isNotEmpty
          ? _override
          : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
                ? 'http://10.0.2.2:8000/'
                : 'http://localhost:8000/'),
    );
    if (!['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw StateError('API_BASE_URL inválida');
    }
    return uri.replace(
      path: uri.path.endsWith('/') ? uri.path : '${uri.path}/',
    );
  }
}
