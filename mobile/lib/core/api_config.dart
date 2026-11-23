import 'package:flutter/foundation.dart';

class ApiConfig {
  // Backend desplegado en AWS (CloudFront -> EC2). No es la dirección de RDS.
  static const String _prod = 'https://d2ml1g66um87p2.cloudfront.net';

  // En desarrollo: con adb reverse, localhost apunta a tu PC por el cable.
  static const String _devHost = 'localhost';

  // Permite elegir la URL al ejecutar: --dart-define=API_URL=https://...
  static const String _override = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kReleaseMode) return _prod;
    return 'http://$_devHost:4001';
  }
}