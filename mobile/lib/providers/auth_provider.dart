import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'mindflow_token';

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  bool isLoading = false;
  String? error;

  /// Se llama al abrir la app: si hay token guardado, lo valida con el backend.
  Future<void> init() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      user = await _service.me(token);
      status = AuthStatus.authenticated;
    } catch (_) {
      await _storage.delete(key: _tokenKey);
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) {
    return _run(() => _service.login(email: email, password: password));
  }

  Future<bool> register({
    required String displayName,
    required String email,
    required String password,
    required String phone,
    required bool allowAiAnalysis,
    required String contactName,
    required String contactPhone,
    required String contactRelation,
  }) {
    return _run(() => _service.register(
          email: email,
          password: password,
          phone: phone,
          displayName: displayName,
          allowAiAnalysis: allowAiAnalysis,
          contactName: contactName,
          contactPhone: contactPhone,
          contactRelation: contactRelation,
        ));
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  Future<bool> _run(Future<AuthResult> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await action();
      await _storage.write(key: _tokenKey, value: result.token);
      user = result.user;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

    /// true = libre, false = ya existe, null = no se pudo comprobar (error de red).
  Future<bool?> isEmailAvailable(String email) async {
    error = null;
    try {
      return await _service.isEmailAvailable(email);
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return null;
    }
  }

    Future<bool> requestPasswordReset(String email) {
    return _runSimple(() => _service.requestPasswordReset(email));
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _runSimple(() => _service.resetPassword(
          email: email,
          code: code,
          newPassword: newPassword,
        ));
  }

  /// Como _run, pero para acciones que no inician sesión.
  Future<bool> _runSimple(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
