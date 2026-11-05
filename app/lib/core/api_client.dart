import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

/// Cliente HTTP hacia el backend Node.js. Guarda el JWT de forma segura.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt';

  /// Android emulator usa 10.0.2.2 para llegar al localhost de tu PC.
  /// En un dispositivo físico, cambia esto por la IP de tu PC o tu URL desplegada.
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  String? _token;

  Future<void> loadToken() async => _token = await _storage.read(key: _tokenKey);
  bool get isLoggedIn => _token != null;

  Future<void> _saveToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  dynamic _handle(http.Response res) {
    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = (body is Map && body['error'] != null)
        ? body['error'].toString()
        : 'Error ${res.statusCode}';
    throw ApiException(res.statusCode, msg);
  }

  Future<dynamic> get(String path) async =>
      _handle(await http.get(Uri.parse('$baseUrl$path'), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> data) async => _handle(
      await http.post(Uri.parse('$baseUrl$path'),
          headers: _headers, body: jsonEncode(data)));

  Future<dynamic> delete(String path) async =>
      _handle(await http.delete(Uri.parse('$baseUrl$path'), headers: _headers));

  // ---- Auth ----
  Future<void> login(String email, String password) async {
    final data = await post('/auth/login', {'email': email, 'password': password});
    await _saveToken(data['token'] as String);
  }

  Future<void> register(String email, String password, String name) async {
    final data = await post('/auth/register',
        {'email': email, 'password': password, 'displayName': name});
    await _saveToken(data['token'] as String);
  }
}
