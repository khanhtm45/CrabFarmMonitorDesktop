import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/auth_models.dart';
import '../models/cloud_telemetry.dart';

class CloudApiException implements Exception {
  CloudApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class CloudApiClient {
  CloudApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _base => AppEnv.cloudApiUrl;

  Future<({String token, AuthUser user})> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_base/api/auth/login');
    final res = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    final body = _decode(res);
    if (res.statusCode == 401 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Email hoặc mật khẩu không đúng.',
        statusCode: res.statusCode,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Đăng nhập thất bại (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    final token = (body['token'] ?? body['Token'])?.toString();
    if (token == null || token.isEmpty) {
      throw CloudApiException('Phản hồi login thiếu token');
    }

    final userRaw = body['user'] ?? body['User'];
    if (userRaw is! Map) {
      throw CloudApiException('Phản hồi login thiếu user');
    }

    return (
      token: token,
      user: AuthUser.fromJson(Map<String, dynamic>.from(userRaw)),
    );
  }

  Future<AuthMePayload> authMe(String token) async {
    final uri = Uri.parse('$_base/api/auth/me');
    final res = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tải được /api/auth/me (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    return AuthMePayload.fromJson(body);
  }

  static String normalizeMac(String mac) =>
      mac.trim().toUpperCase().replaceAll('-', ':');

  Future<CloudTelemetryRealtime> fetchTelemetryRealtime(String mac) async {
    final norm = normalizeMac(mac);
    final uri = Uri.parse('$_base/api/telemetry/realtime')
        .replace(queryParameters: {'mac': norm});
    final res = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    final body = _decode(res);

    if (res.statusCode == 404) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tìm thấy thiết bị $mac',
        statusCode: 404,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ??
            'Không tải realtime (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    final readings = _parseReadingsMap(body['readings']);
    DateTime? lastAt;

    final pins = body['pins'];
    if (pins is List) {
      for (final p in pins) {
        if (p is! Map) continue;
        final m = Map<String, dynamic>.from(p);
        final label = (m['label'] ?? m['Label'])?.toString();
        final val = (m['val'] ?? m['Val']);
        if (label != null && val is num) {
          readings.putIfAbsent(label, () => val.toDouble());
        }
        final t = m['recordedAt'] ?? m['RecordedAt'];
        if (t == null) continue;
        final dt = DateTime.tryParse(t.toString());
        if (dt != null && (lastAt == null || dt.isAfter(lastAt))) {
          lastAt = dt;
        }
      }
    }

    return CloudTelemetryRealtime(
      mac: (body['mac'] ?? norm).toString(),
      deviceCode: (body['deviceCode'] ?? body['DeviceCode'])?.toString(),
      readings: readings,
      lastRecordedAt: lastAt,
    );
  }

  Future<List<CloudTelemetryHistoryPoint>> fetchTelemetryHistory({
    required String token,
    required String mac,
    required int minutes,
    int? pin,
  }) async {
    final params = <String, String>{
      'mac': normalizeMac(mac),
      'minutes': minutes.toString(),
    };
    if (pin != null) params['pin'] = pin.toString();

    final uri = Uri.parse('$_base/api/telemetry/history')
        .replace(queryParameters: params);
    final res = await _client
        .get(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 45));
    final body = _decode(res);

    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode == 404) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tìm thấy thiết bị',
        statusCode: 404,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ??
            'Không tải history (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    final data = body['data'];
    if (data is! List) return [];

    return data.map((row) {
      final m = Map<String, dynamic>.from(row as Map);
      final timeStr = (m['time'] ?? m['Time'])?.toString() ?? '';
      return CloudTelemetryHistoryPoint(
        time: DateTime.tryParse(timeStr) ?? DateTime.now(),
        pin: ((m['pin'] ?? m['Pin']) as num?)?.toInt() ?? 0,
        val: ((m['val'] ?? m['Val']) as num?)?.toDouble() ?? 0,
        label: (m['label'] ?? m['Label'])?.toString() ?? '',
      );
    }).toList();
  }

  Future<bool> healthCheck() async {
    try {
      final res = await _client
          .get(Uri.parse('$_base/health'))
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    if (res.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  String? _errorMessage(Map<String, dynamic> body) {
    final e = body['error'] ?? body['Error'] ?? body['message'] ?? body['Message'];
    return e?.toString();
  }

  static Map<String, double> _parseReadingsMap(dynamic readingsRaw) {
    final readings = <String, double>{};
    if (readingsRaw is Map) {
      readingsRaw.forEach((k, v) {
        if (v is num) readings[k.toString()] = v.toDouble();
      });
    }
    return readings;
  }
}
