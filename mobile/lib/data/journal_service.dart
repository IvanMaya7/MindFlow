import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import 'auth_service.dart' show ApiException;
import 'journal_entry.dart';

class JournalService {
  final String _base = '${ApiConfig.baseUrl}/api/journal';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'mindflow_token';
  static const _timeout = Duration(seconds: 15);

  /// Guarda un registro. Solo [primaryEmotion] es obligatoria;
  /// lo demás se envía únicamente si el usuario lo llenó.
  Future<void> createEntry({
    required String primaryEmotion,
    List<String> bodySensations = const [],
    int? emotionIntensity,
    int? energyLevel,
    int? stressLevel,
    int? sleepQuality,
    List<String> tags = const [],
    String? textNotes,
  }) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw ApiException('Tu sesión expiró. Inicia sesión de nuevo.');
    }

    final body = <String, dynamic>{
      'primaryEmotion': primaryEmotion,
      'bodySensations': bodySensations,
      'tags': tags,
      'emotionIntensity': ?emotionIntensity,
      'energyLevel': ?energyLevel,
      'stressLevel': ?stressLevel,
      'sleepQuality': ?sleepQuality,
      'textNotes': ?textNotes,
    };

    try {
      final res = await http
          .post(
            Uri.parse(_base),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) return;

      var message = 'Ocurrió un error inesperado';
      try {
        final json = jsonDecode(res.body);
        if (json is Map && json['message'] != null) {
          message = json['message'].toString();
        }
      } catch (_) {}
      throw ApiException(message);
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

  /// Trae tus registros más recientes (de más nuevo a más viejo).
  Future<List<JournalEntry>> listEntries({int limit = 60}) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw ApiException('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    try {
      final res = await http
          .get(
            Uri.parse('$_base?limit=$limit'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException('No se pudieron cargar tus registros');
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return (json['entries'] as List)
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder');
    } catch (e) {
      debugPrint('API ERROR -> $_base : $e');
      throw ApiException('No se pudo conectar con el servidor');
    }
  }
}