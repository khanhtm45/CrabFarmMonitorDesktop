import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/mock_water_quality_data.dart';
import '../models/water_quality.dart';
import '../utils/water_trend_window.dart';

/// Xu hướng pH & nhiệt độ cho Dashboard — cửa sổ 30 phút, cập nhật 3s.
class DashboardEnvTrendService extends ChangeNotifier {
  static const rangeMinutes = 30;
  static const pollInterval = Duration(seconds: 3);

  final List<WaterTrendPoint> _buffer = [];
  List<WaterTrendPoint> _points = [];
  WaterTrendPoint? _emaState;
  Timer? _timer;
  bool _active = false;

  List<WaterTrendPoint> get points => _points;
  int get rangeMinutesValue => rangeMinutes;

  void start() {
    if (_active) return;
    _active = true;
    _seed();
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => tick());
  }

  void stop() {
    _active = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  void _seed() {
    _emaState = null;
    _buffer
      ..clear()
      ..addAll(MockWaterQualityData.trendForRange(rangeMinutes));
    _points = WaterTrendWindow.project(_buffer, rangeMinutes);
    notifyListeners();
  }

  void tick() {
    final now = DateTime.now();
    final raw = MockWaterQualityData.trendLiveSample(now);
    _buffer.add(_smoothPoint(raw, now));
    final pruned = WaterTrendWindow.prune(_buffer, rangeMinutes, now);
    _buffer
      ..clear()
      ..addAll(pruned);
    _points = WaterTrendWindow.project(_buffer, rangeMinutes, now);
    notifyListeners();
  }

  /// EMA — giảm nhảy đột ngột mỗi 3s.
  WaterTrendPoint _smoothPoint(WaterTrendPoint raw, DateTime now) {
    final prev = _emaState;
    if (prev == null) {
      _emaState = raw;
      return raw;
    }
    const a = 0.28;
    final x = raw.xMinutes;
    final smoothed = WaterTrendPoint(
      xMinutes: x,
      label: raw.label,
      timestamp: now,
      ph: prev.ph * (1 - a) + raw.ph * a,
      temperature: prev.temperature * (1 - a) + raw.temperature * a,
      tds: raw.tds,
      flow: raw.flow,
      dissolvedOxygen: raw.dissolvedOxygen,
    );
    _emaState = smoothed;
    return smoothed;
  }
}
