import 'package:flutter/foundation.dart';

import '../data/mock_feed_data.dart';
import '../models/feed_management.dart';

class FeedService extends ChangeNotifier {
  FeedService() {
    _selectedDay = DateTime(2026, 5, 24);
    _focusedMonth = DateTime(2026, 5, 1);
  }

  final List<FeedInventoryItem> _inventory =
      List.of(MockFeedData.inventory(), growable: true);
  final List<FeedingScheduleItem> _schedule =
      List.of(MockFeedData.allSchedules(), growable: true);

  String _search = '';
  bool _fcrByBatch = true;
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  static const milestoneDays = {7, 14, 21, 28};

  FeedKpi get kpi {
    final base = MockFeedData.kpi;
    final todayAnchor = DateTime(2026, 5, 24);
    final todayItems =
        _schedule.where((s) => _sameDay(s.scheduledDate, todayAnchor));
    final total = todayItems.length;
    final done = todayItems.where((s) => s.completed).length;
    return FeedKpi(
      totalStockKg: base.totalStockKg,
      stockTrendPercent: base.stockTrendPercent,
      consumedTodayKg: base.consumedTodayKg,
      weeklyAvgKg: base.weeklyAvgKg,
      avgFcr: base.avgFcr,
      fcrTarget: base.fcrTarget,
      feedingsPerDay: total == 0 ? base.feedingsPerDay : total,
      feedingsCompleted: done,
      lowStockCount: base.lowStockCount,
      monthlyConsumedKg: base.monthlyConsumedKg,
    );
  }

  String get aiInsight => MockFeedData.aiInsight;
  String get aiRecommendation => MockFeedData.aiRecommendation;
  FeedPortionSuggestion get portion => MockFeedData.portionSuggestion();

  bool get fcrByBatch => _fcrByBatch;
  DateTime get focusedMonth => _focusedMonth;
  DateTime get selectedDay => _selectedDay;

  int get feedingStreak => _computeStreak(anchor: DateTime(2026, 5, 24));
  int get nextMilestone {
    for (final m in milestoneDays) {
      if (feedingStreak < m) return m;
    }
    return feedingStreak + 7;
  }

  List<BatchFeedConsumption> get batchConsumption => MockFeedData.batchConsumption();
  List<DailyFeedConsumption> get dailyConsumption => MockFeedData.dailyConsumption();

  List<FeedInventoryItem> get inventory {
    if (_search.trim().isEmpty) return List.unmodifiable(_inventory);
    final q = _search.toLowerCase();
    return _inventory
        .where(
          (i) =>
              i.code.toLowerCase().contains(q) ||
              i.name.toLowerCase().contains(q),
        )
        .toList();
  }

  List<FeedingScheduleItem> get schedule {
    final day = _selectedDay;
    return _schedule
        .where((s) => _sameDay(s.scheduledDate, day))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  List<FeedCalendarDayState> calendarDaysForFocusedMonth() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final last = DateTime(year, month + 1, 0).day;
    final today = DateTime(2026, 5, 24);

    final completeDays = <DateTime>{};
    for (var d = 1; d <= last; d++) {
      final date = DateTime(year, month, d);
      final items = _schedule.where((s) => _sameDay(s.scheduledDate, date));
      if (items.isEmpty) continue;
      if (items.every((s) => s.completed)) {
        completeDays.add(date);
      }
    }

    final streakMap = _streakSegments(completeDays, year, month);

    return List.generate(last, (i) {
      final day = i + 1;
      final date = DateTime(year, month, day);
      final items = _schedule.where((s) => _sameDay(s.scheduledDate, date)).toList();
      final completed = items.where((s) => s.completed).length;
      return FeedCalendarDayState(
        date: date,
        total: items.length,
        completed: completed,
        isToday: _sameDay(date, today),
        isSelected: _sameDay(date, _selectedDay),
        isMilestone: milestoneDays.contains(day) && completeDays.contains(date),
        streakSegment: streakMap[day] ?? 'none',
      );
    });
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setFcrView(bool byBatch) {
    _fcrByBatch = byBatch;
    notifyListeners();
  }

  void setFocusedMonth(DateTime month) {
    _focusedMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
  }

  void previousMonth() {
    setFocusedMonth(DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1));
  }

  void nextMonth() {
    setFocusedMonth(DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1));
  }

  void selectDay(DateTime day) {
    _selectedDay = DateTime(day.year, day.month, day.day);
    notifyListeners();
  }

  void addSchedule({
    required DateTime date,
    required String time,
    required String area,
    required String batchId,
    required String feedName,
    required double portionKg,
    String repeatRule = 'Hàng ngày',
  }) {
    final id = 'sch-${DateTime.now().millisecondsSinceEpoch}';
    _schedule.add(
      FeedingScheduleItem(
        id: id,
        scheduledDate: DateTime(date.year, date.month, date.day),
        time: time,
        area: area,
        batchId: batchId,
        feedName: feedName,
        portionKg: portionKg,
        completed: false,
        repeatRule: repeatRule,
      ),
    );
    _selectedDay = DateTime(date.year, date.month, date.day);
    _focusedMonth = DateTime(date.year, date.month, 1);
    notifyListeners();
  }

  void importStock(String code, double kg) {
    final i = _inventory.indexWhere((x) => x.code == code);
    if (i >= 0) {
      final item = _inventory[i];
      _inventory[i] = FeedInventoryItem(
        id: item.id,
        code: item.code,
        name: item.name,
        typeLabel: item.typeLabel,
        stockKg: item.stockKg + kg,
        unit: item.unit,
        expiryDate: item.expiryDate,
        status: item.status,
      );
      notifyListeners();
    }
  }

  void exportStock(String code, double kg) {
    final i = _inventory.indexWhere((x) => x.code == code);
    if (i >= 0) {
      final item = _inventory[i];
      _inventory[i] = FeedInventoryItem(
        id: item.id,
        code: item.code,
        name: item.name,
        typeLabel: item.typeLabel,
        stockKg: (item.stockKg - kg).clamp(0, 9999),
        unit: item.unit,
        expiryDate: item.expiryDate,
        status: item.stockKg - kg < 50 ? FeedStockStatus.low : item.status,
      );
      notifyListeners();
    }
  }

  void feedNow(String scheduleId) {
    final i = _schedule.indexWhere((s) => s.id == scheduleId);
    if (i >= 0) {
      _schedule[i].completed = true;
      _schedule[i].completedAt = 'Vừa xong';
      notifyListeners();
    }
  }

  void completeNextSchedule() {
    final i = _schedule.indexWhere((s) => !s.completed);
    if (i >= 0) feedNow(_schedule[i].id);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _computeStreak({required DateTime anchor}) {
    var streak = 0;
    var d = DateTime(anchor.year, anchor.month, anchor.day);
    while (true) {
      final items = _schedule.where((s) => _sameDay(s.scheduledDate, d));
      if (items.isEmpty || !items.every((s) => s.completed)) break;
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Map<int, String> _streakSegments(Set<DateTime> completeDays, int year, int month) {
    final result = <int, String>{};
    final sorted = completeDays
        .where((d) => d.year == year && d.month == month)
        .map((d) => d.day)
        .toList()
      ..sort();

    if (sorted.isEmpty) return result;

    var runStart = sorted.first;
    var prev = sorted.first;
    for (var i = 1; i <= sorted.length; i++) {
      final atEnd = i == sorted.length;
      final day = atEnd ? null : sorted[i];
      if (!atEnd && day == prev + 1) {
        prev = day!;
        continue;
      }
      _assignRun(result, runStart, prev);
      if (!atEnd) {
        runStart = day!;
        prev = day;
      }
    }
    return result;
  }

  void _assignRun(Map<int, String> map, int start, int end) {
    if (start == end) {
      map[start] = 'single';
      return;
    }
    for (var d = start; d <= end; d++) {
      if (d == start) {
        map[d] = 'start';
      } else if (d == end) {
        map[d] = 'end';
      } else {
        map[d] = 'middle';
      }
    }
  }
}
