import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import 'resource.dart';
import 'resource_catalog.dart';

/// Consumo del catálogo de recursos y guías.
///
/// Contrato esperado del servicio remoto:
///
///   GET  {ApiConfig.baseUrl}/api/resources?lang=es
///        (o {RESOURCES_API_URL}?lang=es si se define con --dart-define)
///   200  { "resources": [ { "id", "title", "description", "category",
///                           "imageUrl", "author", "readMinutes", "kind",
///                           "tags", "content", "audioUrl" } ] }
///   o bien una lista simple: [ { ... }, { ... } ]
///
/// Si el servicio no responde (por ejemplo, mientras se define la API gratuita
/// de contenido), la pantalla sigue funcionando con el catálogo local curado.
class ResourceService {
  static const String _override = String.fromEnvironment('RESOURCES_API_URL');

  final String _base =
      _override.isNotEmpty ? _override : '${ApiConfig.baseUrl}/api/resources';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'mindflow_token';
  static const _savedKey = 'mindflow_saved_resources';
  static const _timeout = Duration(seconds: 6);

  Future<List<Resource>> fetchResources({String lang = 'es'}) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final uri = Uri.parse(_base).replace(queryParameters: {'lang': lang});
      final res = await http.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Respuesta ${res.statusCode} del catálogo de recursos');
      }

      final decoded = jsonDecode(res.body);
      final raw = decoded is List
          ? decoded
          : (decoded is Map ? decoded['resources'] : null);

      if (raw is! List) {
        throw Exception('Formato de catálogo no reconocido');
      }

      final resources = raw
          .whereType<Map>()
          .map((e) => Resource.fromJson(Map<String, dynamic>.from(e)))
          .where((r) => r.id.isNotEmpty && r.title.isNotEmpty)
          .toList();

      if (resources.isEmpty) {
        throw Exception('El catálogo de recursos llegó vacío');
      }

      return resources;
    } catch (e) {
      debugPrint('RESOURCES API -> usando catálogo local: $e');
      return ResourceCatalog.resources;
    }
  }

  // ---------------- Artículos guardados ----------------

  Future<Set<String>> loadSavedIds() async {
    try {
      final raw = await _storage.read(key: _savedKey);
      if (raw == null || raw.isEmpty) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.map((e) => e.toString()).toSet();
    } catch (e) {
      debugPrint('No se pudieron leer los recursos guardados: $e');
      return <String>{};
    }
  }

  Future<void> saveSavedIds(Set<String> ids) async {
    try {
      await _storage.write(key: _savedKey, value: jsonEncode(ids.toList()));
    } catch (e) {
      debugPrint('No se pudieron guardar los recursos: $e');
    }
  }
}
