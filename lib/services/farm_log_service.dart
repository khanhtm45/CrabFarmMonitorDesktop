import 'package:flutter/foundation.dart';

import '../data/mock_farm_activity_log_data.dart';
import '../models/farm_activity_log.dart';

class FarmLogService extends ChangeNotifier {
  final List<FarmActivityLogEntry> _entries =
      List.of(MockFarmActivityLogData.entries(), growable: true);

  String _timeFilter = 'Hôm nay';
  String _typeFilter = 'Tất cả';
  String _performerFilter = 'Tất cả';
  String _areaFilter = 'Tất cả';
  String _batchFilter = 'Tất cả';
  String _search = '';
  String? _selectedId = 'log-001';
  bool _timelineView = false;

  FarmLogKpi get kpi => MockFarmActivityLogData.kpi;
  FarmLogAiSummary get aiSummary => MockFarmActivityLogData.aiSummary;

  String get timeFilter => _timeFilter;
  String get typeFilter => _typeFilter;
  String get performerFilter => _performerFilter;
  String get areaFilter => _areaFilter;
  String get batchFilter => _batchFilter;
  bool get timelineView => _timelineView;

  FarmActivityLogEntry? get selectedEntry {
    if (_selectedId == null) return null;
    try {
      return _entries.firstWhere((e) => e.id == _selectedId);
    } catch (_) {
      return _entries.isNotEmpty ? _entries.first : null;
    }
  }

  List<FarmActivityLogEntry> get filteredEntries {
    var list = _entries;
    if (_typeFilter != 'Tất cả') {
      list = list.where((e) => e.type.label == _typeFilter).toList();
    }
    if (_performerFilter != 'Tất cả') {
      list = list.where((e) => e.performer == _performerFilter).toList();
    }
    if (_areaFilter != 'Tất cả') {
      list = list
          .where((e) => e.area.toLowerCase().contains(_areaFilter.toLowerCase()))
          .toList();
    }
    if (_batchFilter != 'Tất cả') {
      list = list.where((e) => e.batchId == _batchFilter).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (e) =>
                e.content.toLowerCase().contains(q) ||
                e.crabId.toLowerCase().contains(q) ||
                e.performer.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setTimeFilter(String v) {
    _timeFilter = v;
    notifyListeners();
  }

  void setTypeFilter(String v) {
    _typeFilter = v;
    notifyListeners();
  }

  void setPerformerFilter(String v) {
    _performerFilter = v;
    notifyListeners();
  }

  void setAreaFilter(String v) {
    _areaFilter = v;
    notifyListeners();
  }

  void setBatchFilter(String v) {
    _batchFilter = v;
    notifyListeners();
  }

  void setTimelineView(bool v) {
    _timelineView = v;
    notifyListeners();
  }

  void selectEntry(String id) {
    _selectedId = id;
    notifyListeners();
  }

  void addEntry({
    required String typeLabel,
    required String performer,
    required String area,
    required String content,
    String batchId = '',
    String crabId = '',
    String note = '',
  }) {
    final type = _typeFromLabel(typeLabel);
    final now = DateTime.now();
    final entry = FarmActivityLogEntry(
      id: 'log-${now.millisecondsSinceEpoch}',
      logCode:
          'LOG-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${_entries.length + 1}',
      time:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      logDate:
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      type: type,
      content: content,
      performer: performer,
      area: area,
      batchId: batchId,
      crabId: crabId,
      note: note,
      subjectDetail: content,
    );
    _entries.insert(0, entry);
    _selectedId = entry.id;
    notifyListeners();
  }

  FarmLogType _typeFromLabel(String label) {
    for (final t in FarmLogType.values) {
      if (t.label == label) return t;
    }
    if (label == 'Điều trị bệnh') return FarmLogType.disease;
    return FarmLogType.other;
  }
}
