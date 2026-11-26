import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import 'auth_service.dart' show ApiException;

class TrustedContact {
  TrustedContact({required this.name, required this.phone, required this.relation});

  final String name;
  final String phone;
  final String relation;

  factory TrustedContact.fromJson(Map<String, dynamic> j) => TrustedContact(
        name: (j['name'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        relation: (j['relation'] ?? '').toString(),
      );
}

class ContactsService {
  final String _base = '${ApiConfig.baseUrl}/api/contacts';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'mindflow_token';
  static const _timeout = Duration(seconds: 15);

  Future<List<TrustedContact>> list() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw ApiException('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    try {
      final res = await http
          .get(Uri.parse(_base), headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException('No se pudieron cargar tus contactos');
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return (json['contacts'] as List)
          .map((e) => TrustedContact.fromJson(e as Map<String, dynamic>))
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