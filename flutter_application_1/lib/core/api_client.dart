import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'http_client.dart';
import 'session_storage.dart';

class ApiClient {
  ApiClient({http.Client? client, Uri? baseUri, SessionStorage? storage})
    : _client = client ?? createHttpClient(),
      _baseUri = baseUri ?? ApiConfig.baseUri,
      _storage = storage ?? const SessionStorage();
  final http.Client _client;
  final Uri _baseUri;
  final SessionStorage _storage;

  Uri _uri(String path, Map<String, String>? query) {
    final relative = Uri.parse(path);
    if (!path.startsWith('/') ||
        relative.hasAuthority ||
        relative.hasScheme ||
        relative.hasQuery ||
        relative.hasFragment ||
        relative.pathSegments.contains('..')) {
      throw ArgumentError('Ruta API inválida');
    }
    return _baseUri.resolve(path.substring(1)).replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers(bool authenticated) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (authenticated && !kIsWeb) {
      final token = await _storage.read();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> _send(http.BaseRequest request) async {
    try {
      final response = await (() async {
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(ApiConfig.timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String? detail;
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map && decoded['detail'] is String) {
            detail = decoded['detail'] as String;
          }
        } on FormatException {
          /* Respuesta no JSON. */
        }
        throw ApiException(
          detail ?? 'Error HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
      return response;
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw const ApiException('No se pudo comunicar con el servidor.');
    }
  }

  Future<dynamic> json(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    final request = http.Request(method, _uri(path, query));
    request.headers.addAll(await _headers(authenticated));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    final response = await _send(request);
    if (response.bodyBytes.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ApiException('Respuesta inválida del servidor.');
    }
  }

  Future<Uint8List> bytes(String path, {bool authenticated = true}) async {
    final request = http.Request('GET', _uri(path, null));
    request.headers.addAll(await _headers(authenticated));
    request.headers['Accept'] = 'image/*';
    return (await _send(request)).bodyBytes;
  }

  void close() => _client.close();
}
