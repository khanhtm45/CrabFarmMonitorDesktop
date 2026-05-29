import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../models/auth_models.dart';
import '../models/cloud_telemetry.dart';
import '../models/farm_record.dart';

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

  Map<String, String> authHeaders(String token, {String? farmId}) => {
        'Authorization': 'Bearer $token',
        if (farmId != null && farmId.isNotEmpty) 'X-Farm-Id': farmId,
      };

  Future<List<FarmRecord>> fetchFarmRecords(String token) async {
    final uri = Uri.parse('$_base/api/farms');
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không tải farms (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final raw = body['farms'] ?? body['Farms'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => FarmRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<FarmSummary>> fetchFarms(String token) async {
    final records = await fetchFarmRecords(token);
    return records.map((f) => f.toSummary()).toList();
  }

  Future<String> fetchNextFarmCode(String token) async {
    final uri = Uri.parse('$_base/api/farms/next-code');
    final res = await _client.get(uri, headers: authHeaders(token));
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không lấy mã trại (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return (body['code'] ?? body['Code'] ?? '').toString();
  }

  Future<FarmRecord> createFarm(
    String token, {
    required String name,
    String? address,
    String? description,
  }) async {
    final uri = Uri.parse('$_base/api/farms');
    final res = await _client.post(
      uri,
      headers: {
        ...authHeaders(token),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'address': address,
        'description': description,
      }),
    );
    return _parseFarmMutation(res);
  }

  Future<FarmRecord> updateFarm(
    String token,
    String farmId, {
    required String name,
    String? address,
    String? description,
  }) async {
    final uri = Uri.parse('$_base/api/farms/$farmId');
    final res = await _client.put(
      uri,
      headers: {
        ...authHeaders(token),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'address': address,
        'description': description,
      }),
    );
    return _parseFarmMutation(res);
  }

  Future<void> deleteFarm(String token, String farmId) async {
    final uri = Uri.parse('$_base/api/farms/$farmId');
    final res = await _client.delete(uri, headers: authHeaders(token));
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode == 204) return;
    final body = _decode(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không xóa được trại (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
  }

  FarmRecord _parseFarmMutation(http.Response res) {
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode == 403) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không có quyền',
        statusCode: 403,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Thao tác thất bại (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final farmRaw = body['farm'] ?? body['Farm'];
    if (farmRaw is! Map) {
      throw CloudApiException('Phản hồi thiếu farm');
    }
    return FarmRecord.fromJson(Map<String, dynamic>.from(farmRaw));
  }

  Future<AuthMePayload> authMe(String token) async {
    final uri = Uri.parse('$_base/api/auth/me');
    final res = await _client.get(
      uri,
      headers: authHeaders(token),
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
    String? farmId,
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
          headers: authHeaders(token, farmId: farmId),
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
