import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Biến môi trường từ `.env` (Cloud only).
abstract final class AppEnv {
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    await dotenv.load(fileName: '.env');
    _loaded = true;
  }

  static String get cloudApiUrl {
    final raw = dotenv.env['CLOUD_API_URL']?.trim();
    if (raw == null || raw.isEmpty) {
      throw StateError('Thiếu CLOUD_API_URL trong .env');
    }
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static String? get defaultFarmId {
    final v = dotenv.env['DEFAULT_FARM_ID']?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  static String? get defaultDeviceMac {
    final v = dotenv.env['DEFAULT_DEVICE_MAC']?.trim();
    return v == null || v.isEmpty ? null : v;
  }
}
