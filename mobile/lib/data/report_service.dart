import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import 'auth_service.dart' show ApiException;

class ReportShare {
  ReportShare(this.url, this.expiresAt);
  final String url;
  final DateTime expiresAt;
}

class ReportService {
  final String _base = '${ApiConfig.baseUrl}/api/reports/share';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'mindflow_token';
  static const _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw ApiException('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String _errorMessage(http.Response res) {
    try {
      final json = jsonDecode(res.body);
      if (json is Map && json['message'] != null) return json['message'].toString();
    } catch (_) {}
    return 'Ocurrió un error inesperado';
  }

  /// Genera un enlace temporal (15 min) con el reporte de los últimos [periodDays] días.
  Future<ReportShare> createShare({required int periodDays}) async {
    final headers = await _headers();
    try {
      final res = await http
          .post(
            Uri.parse('$_base?tz=${DateTime.now().timeZoneOffset.inMinutes}'),
            headers: headers,
            body: jsonEncode({'periodDays': periodDays}),
          )
          .timeout(_timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(_errorMessage(res));
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return ReportShare(
        json['url'] as String,
        DateTime.parse(json['expiresAt'] as String).toLocal(),
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder');
    } catch (e) {
      debugPrint('API ERROR -> $_base : $e');
      throw ApiException('No se pudo conectar con el servidor');
    }
  }

  /// Corta el enlace vigente (si lo hay).
  Future<void> revoke() async {
    final headers = await _headers();
    try {
      await http.delete(Uri.parse(_base), headers: headers).timeout(_timeout);
    } catch (e) {
      debugPrint('API ERROR -> $_base : $e');
    }
  }
}