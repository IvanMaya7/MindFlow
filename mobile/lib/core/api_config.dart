import 'package:flutter/foundation.dart';

class ApiConfig {
  // Cambia esto por la URL de tu backend desplegado en AWS.
  static const String _prod = 'https://mindflow.c7e64ss8uk7z.us-east-2.rds.amazonaws.com';

  // IP de tu PC en la red local (ipconfig -> IPv4). Cambia si tu router te da otra.
  static const String _devHost = 'localhost';

  static String get baseUrl {
    if (kReleaseMode) return _prod;
    return 'http://$_devHost:4001';
  }
}