import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  /// Bisa ditimpa saat menjalankan, misalnya untuk HP asli:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    // Emulator Android: 10.0.2.2 = komputer host (localhost milik emulator sendiri tidak dipakai)
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  static const Duration requestTimeout = Duration(seconds: 20);
}