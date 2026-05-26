import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../data/mock_water_quality_data.dart';
import '../models/auth_models.dart';
import '../models/cloud_telemetry.dart';
import '../models/water_quality.dart';
import 'cloud_api_client.dart';
import '../utils/water_trend_window.dart';
import 'water_quality_cloud_merge.dart';

class WaterQualityService extends ChangeNotifier {
  WaterQualityService({
    required AuthSession session,
    CloudApiClient? api,
    String? deviceMac,
  })  : _session = session,
        _api = api ?? CloudApiClient(),
        _mac = CloudApiClient.normalizeMac(
          deviceMac ?? AppEnv.defaultDeviceMac ?? '',
        ) {
    _readings = MockWaterQualityData.currentReadings();
    _seedTrendBuffer();
    _history = MockWaterQualityData.historyRows();
  }

  void _seedTrendBuffer() {
    _trendBuffer
      ..clear()
      ..addAll(MockWaterQualityData.trendForRange(chartRangeMinutesValue));
    _trendPoints = WaterTrendWindow.project(_trendBuffer, chartRangeMinutesValue);
  }

  final AuthSession _session;
  final CloudApiClient _api;
  final String _mac;

  static const _pollInterval = Duration(seconds: 3);

  static const chartRangeLabels = ['30 phút', '1 giờ', '24 giờ'];
  static const chartRangeMinutes = [30, 60, 24 * 60];

  List<WaterSensorReading> _readings = [];
  List<WaterTrendPoint> _trendPoints = [];
  final List<WaterTrendPoint> _trendBuffer = [];
  List<WaterHistoryRow> _history = [];

  String _area = 'Khu A';
  String _device = 'Sensor-01';
  String _timeRange = '24h';
  String _statusFilter = 'Tất cả';
  int _chartRangeIndex = 0;

  bool _chartLoading = false;
  String? _trendError;

  bool _loading = false;
  bool _cloudLive = false;
  String? _cloudError;
  String? _historyError;
  String? _deviceCode;
  DateTime? _lastRealtimeAt;

  Timer? _pollTimer;
  bool _pollActive = false;
  bool _realtimeBusy = false;
  bool _trendBusy = false;

  List<WaterSensorReading> get readings => List.unmodifiable(_readings);
  String get area => _area;
  String get device => _device;
  String get timeRange => _timeRange;
  String get statusFilter => _statusFilter;
  int get chartRangeIndex => _chartRangeIndex;
  String get chartRangeLabel => chartRangeLabels[_chartRangeIndex];
  int get chartRangeMinutesValue => chartRangeMinutes[_chartRangeIndex];
  bool get isLoading => _loading;
  bool get chartLoading => _chartLoading;
  String? get trendError => _trendError;
  bool get cloudLive => _cloudLive;
  String? get cloudError => _cloudError;
  String? get historyError => _historyError;
  String? get deviceMac => _mac.isEmpty ? null : _mac;
  String? get deviceCode => _deviceCode;
  DateTime? get lastRealtimeAt => _lastRealtimeAt;

  List<WaterSensorReading> get filteredReadings {
    var list = _readings;
    if (_statusFilter == 'Bình thường') {
      list = list
          .where(
            (r) =>
                r.status == WaterSensorStatus.normal ||
                r.status == WaterSensorStatus.good,
          )
          .toList();
    } else if (_statusFilter == 'Cảnh báo') {
      list = list
          .where(
            (r) =>
                r.status == WaterSensorStatus.exceeded ||
                r.status == WaterSensorStatus.danger ||
                r.status == WaterSensorStatus.monitoring,
          )
          .toList();
    } else if (_statusFilter == 'Offline') {
      list = list.where((r) => r.offline).toList();
    }
    return list;
  }

  List<WaterTrendPoint> get trendPoints => _trendPoints;
  List<WaterHistoryRow> get history => _history;

  /// Bật poll realtime mỗi 3s (gọi từ màn Cảm biến môi trường).
  void startLiveUpdates() {
    if (_pollActive) return;
    _pollActive = true;
    _pollTimer?.cancel();
    unawaited(_liveCycle(full: true));
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_liveCycle(full: false));
    });
  }

  void stopLiveUpdates() {
    _pollActive = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _liveCycle({required bool full}) async {
    await refresh(full: full);
    await refreshTrend(quiet: !full);
  }

  @override
  void dispose() {
    stopLiveUpdates();
    super.dispose();
  }

  /// [full]: true = realtime + history; false = chỉ realtime (poll).
  Future<void> refresh({bool full = true}) async {
    if (_mac.isEmpty) {
      _cloudLive = false;
      _cloudError = 'Thiếu DEFAULT_DEVICE_MAC trong .env';
      _applyMockOnly();
      notifyListeners();
      return;
    }

    if (full) {
      _loading = true;
      _cloudError = null;
      _historyError = null;
      notifyListeners();
    } else if (_realtimeBusy) {
      return;
    }

    _realtimeBusy = true;
    CloudTelemetryRealtime? realtime;

    try {
      realtime = await _api.fetchTelemetryRealtime(_mac);
      _deviceCode = realtime.deviceCode;
      if (realtime.deviceCode != null && realtime.deviceCode!.isNotEmpty) {
        _device = realtime.deviceCode!;
      }
      _lastRealtimeAt = realtime.lastRecordedAt ?? DateTime.now();
      _cloudLive = true;
      _cloudError = null;
      _readings = WaterQualityCloudMerge.mergeReadings(realtime);
      notifyListeners();
    } on CloudApiException catch (e) {
      _cloudLive = false;
      _cloudError = e.message;
      if (full) _applyMockOnly();
      notifyListeners();
    } catch (e) {
      _cloudLive = false;
      _cloudError = 'Realtime: $e';
      if (full) _applyMockOnly();
      notifyListeners();
    } finally {
      _realtimeBusy = false;
    }

    if (!full) return;

    await Future.wait([refreshTrend(quiet: false), _loadHistoryTable()]);

    _loading = false;
    notifyListeners();
  }

  /// Cửa sổ realtime [now - range, now] — poll mỗi 3s cùng gauge.
  Future<void> refreshTrend({bool quiet = false}) async {
    if (_trendBusy) return;
    _trendBusy = true;

    final range = chartRangeMinutesValue;
    final now = DateTime.now();

    if (!quiet) {
      _chartLoading = true;
      _trendError = null;
      notifyListeners();
    }

    try {
      if (_mac.isEmpty || !_cloudLive) {
        _pushMockTrendTick(now, range);
      } else {
        final histPoints = await _api.fetchTelemetryHistory(
          token: _session.token,
          mac: _mac,
          minutes: range,
        );
        final built = WaterQualityCloudMerge.buildTrend(
          histPoints,
          range,
          MockWaterQualityData.trendForRange(range),
        );
        _trendBuffer
          ..clear()
          ..addAll(built);
        _trendPoints = WaterTrendWindow.project(_trendBuffer, range, now);
        _trendError = null;
      }
    } on CloudApiException catch (e) {
      _trendError = e.message;
      _pushMockTrendTick(now, range);
    } catch (e) {
      _trendError = '$e';
      _pushMockTrendTick(now, range);
    } finally {
      _trendBusy = false;
      if (!quiet) _chartLoading = false;
      notifyListeners();
    }
  }

  void _pushMockTrendTick(DateTime now, int rangeMinutes) {
    final sample = _trendPointFromReadingsOrMock(now);
    _trendBuffer.add(sample);
    final pruned = WaterTrendWindow.prune(_trendBuffer, rangeMinutes, now);
    _trendBuffer
      ..clear()
      ..addAll(pruned);
    _trendPoints = WaterTrendWindow.project(_trendBuffer, rangeMinutes, now);
  }

  WaterTrendPoint _trendPointFromReadingsOrMock(DateTime now) {
    double? v(WaterSensorType t) {
      for (final r in _readings) {
        if (r.type == t) return r.value;
      }
      return null;
    }

    final mock = MockWaterQualityData.trendLiveSample(now);
    return WaterTrendPoint(
      xMinutes: 0,
      label: mock.label,
      timestamp: now,
      ph: v(WaterSensorType.ph) ?? mock.ph,
      temperature: v(WaterSensorType.temperature) ?? mock.temperature,
      tds: v(WaterSensorType.tds) ?? mock.tds,
      flow: v(WaterSensorType.flow) ?? mock.flow,
      dissolvedOxygen: mock.dissolvedOxygen,
    );
  }

  /// Tải lại biểu đồ (đổi khoảng thời gian).
  Future<void> loadTrendChart() => refreshTrend(quiet: false);

  Future<void> _loadHistoryTable() async {
    try {
      final histPoints = await _api.fetchTelemetryHistory(
        token: _session.token,
        mac: _mac,
        minutes: _minutesForFilterRange(_timeRange),
      );
      _history = WaterQualityCloudMerge.buildHistory(
        histPoints,
        MockWaterQualityData.historyRows(),
      );
      _historyError = null;
    } on CloudApiException catch (e) {
      _historyError = e.message;
      _history = MockWaterQualityData.historyRows();
    } catch (e) {
      _historyError = 'History: $e';
      _history = MockWaterQualityData.historyRows();
    }
  }

  void _applyMockOnly() {
    _readings = MockWaterQualityData.currentReadings();
    _seedTrendBuffer();
    _history = MockWaterQualityData.historyRows();
  }

  int _minutesForFilterRange(String range) => switch (range) {
        '7 ngày' => 60 * 24 * 7,
        '30 ngày' => 60 * 24 * 30,
        _ => 60 * 24,
      };

  void setArea(String v) {
    _area = v;
    notifyListeners();
  }

  void setDevice(String v) {
    _device = v;
    notifyListeners();
  }

  void setTimeRange(String v) {
    _timeRange = v;
    refresh(full: true);
  }

  void setStatusFilter(String v) {
    _statusFilter = v;
    notifyListeners();
  }

  void setChartRangeIndex(int i) {
    _chartRangeIndex = i.clamp(0, chartRangeLabels.length - 1);
    _seedTrendBuffer();
    refreshTrend(quiet: false);
  }

  String get aiInsight => _cloudLive
      ? 'Realtime Cloud mỗi ${_pollInterval.inSeconds}s — '
          'nhiệt, pH, TDS, lưu lượng, mực nước từ $_mac. '
          'DO/mặn/ORP/NH3/NO2: mock.'
      : MockWaterQualityData.aiInsight;

  List<String> get aiRecommendations => _cloudLive
      ? [
          'Nguồn: ${AppEnv.cloudApiUrl}/api/telemetry/realtime',
          if (_lastRealtimeAt != null)
            'Cập nhật gần nhất: $_lastRealtimeAt',
          if (_trendError != null) 'Biểu đồ: $_trendError',
          if (_historyError != null) 'Lịch sử: $_historyError',
          if (_cloudError != null) 'Lỗi: $_cloudError',
          ...MockWaterQualityData.aiRecommendations,
        ]
      : MockWaterQualityData.aiRecommendations;
}
