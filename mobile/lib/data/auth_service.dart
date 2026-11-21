import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String theme;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.theme,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        theme: (json['theme'] as String?) ?? 'system',
      );
}

class AuthResult {
  final AppUser user;
  final String token;
  AuthResult({required this.user, required this.token});
}

class AuthService {
  final String _base = '${ApiConfig.baseUrl}/api/auth';
  static const _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    try {
      final res = await request().timeout(_timeout);
      final body = res.body.isNotEmpty
          ? jsonDecode(res.body) as Map<String, dynamic>
          : <String, dynamic>{};
      if (res.statusCode >= 200 && res.statusCode < 300) return body;
      throw ApiException(body['message']?.toString() ?? 'Ocurrió un error inesperado');
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      debugPrint('API TIMEOUT -> $_base : $e');
      throw ApiException('El servidor tardó demasiado en responder');
    } catch (e) {
      debugPrint('API ERROR -> $_base : $e');
      throw ApiException('No se pudo conectar con el servidor');
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    required bool allowAiAnalysis,
    required String contactName,
    required String contactPhone,
    String? contactRelation,
  }) async {
    final data = await _send(() => http.post(
          Uri.parse('$_base/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'displayName': displayName,
            'allowAiAnalysis': allowAiAnalysis,
            'emergencyContact': {
              'name': contactName,
              'phone': contactPhone,
              'relation': ?contactRelation,
            },
          }),
        ));
    return AuthResult(
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final data = await _send(() => http.post(
          Uri.parse('$_base/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        ));
    return AuthResult(
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
  }

  Future<AppUser> me(String token) async {
    final data = await _send(() => http.get(
          Uri.parse('$_base/me'),
          headers: {'Authorization': 'Bearer $token'},
        ));
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }
}
