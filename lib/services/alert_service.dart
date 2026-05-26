import 'package:flutter/foundation.dart';

import '../data/mock_alerts_data.dart';
import '../models/farm_alert.dart';

class AlertService extends ChangeNotifier {
  final List<FarmAlert> _alerts =
      List.of(MockAlertsData.alerts(), growable: true);

  String _filter = 'Tất cả';
  String _search = '';
  String? _selectedId = 'alt-001';

  AlertKpi get kpi => MockAlertsData.kpi;
  FarmAlert get spotlight => MockAlertsData.spotlightAlert;
  List<AlertHistoryRow> get history => MockAlertsData.history();
  List<AlertFrequencyPoint> get frequency => MockAlertsData.frequency24h();
  List<NotificationChannelConfig> get channelRules =>
      MockAlertsData.channelRules();

  String get aiInsight => MockAlertsData.aiInsight;
  List<String> get aiRecommendations => MockAlertsData.aiRecommendations;

  String get filter => _filter;

  FarmAlert? get selectedAlert {
    if (_selectedId == null) return null;
    try {
      return _alerts.firstWhere((a) => a.id == _selectedId);
    } catch (_) {
      return _alerts.isNotEmpty ? _alerts.first : null;
    }
  }

  List<FarmAlert> get filteredAlerts {
    var list = _alerts;
    switch (_filter) {
      case 'Info':
        list = list.where((a) => a.level == AlertLevel.info).toList();
      case 'Warning':
        list = list.where((a) => a.level == AlertLevel.warning).toList();
      case 'Critical':
        list = list.where((a) => a.level == AlertLevel.critical).toList();
      case 'Chưa xử lý':
        list = list.where((a) => a.isOpen).toList();
      case 'Đã xử lý':
        list = list
            .where((a) => a.status == AlertWorkflowStatus.resolved)
            .toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (a) =>
                a.title.toLowerCase().contains(q) ||
                a.location.toLowerCase().contains(q) ||
                a.device.toLowerCase().contains(q) ||
                a.handler.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setFilter(String v) {
    _filter = v;
    notifyListeners();
  }

  void selectAlert(String id) {
    _selectedId = id;
    notifyListeners();
  }

  void markInProgress(String id, {String handler = 'Admin'}) {
    _update(id, status: AlertWorkflowStatus.inProgress, handler: handler);
  }

  void markResolved(String id, {String handler = 'Admin'}) {
    _update(id, status: AlertWorkflowStatus.resolved, handler: handler);
  }

  void markIgnored(String id) {
    _update(id, status: AlertWorkflowStatus.ignored);
  }

  void _update(
    String id, {
    AlertWorkflowStatus? status,
    String? handler,
    String? note,
  }) {
    final i = _alerts.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final a = _alerts[i];
    _alerts[i] = FarmAlert(
      id: a.id,
      time: a.time,
      level: a.level,
      type: a.type,
      title: a.title,
      location: a.location,
      device: a.device,
      status: status ?? a.status,
      handler: handler ?? a.handler,
      currentValue: a.currentValue,
      threshold: a.threshold,
      recommendations: a.recommendations,
      suggestedActions: a.suggestedActions,
      detectedAt: a.detectedAt,
      note: note ?? a.note,
    );
    notifyListeners();
  }
}
