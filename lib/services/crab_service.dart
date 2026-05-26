import 'package:flutter/foundation.dart';

import '../data/mock_crab_data.dart';
import '../models/crab_individual.dart';
import '../models/crab_status.dart';

class CrabService extends ChangeNotifier {
  CrabService() : _crabs = MockCrabData.initialCrabs();

  List<CrabIndividual> _crabs;

  List<CrabIndividual> get crabs => List.unmodifiable(_crabs);

  String _searchQuery = '';
  String _batchFilter = MockCrabData.batchOptions.first;
  String _lifeFilter = MockCrabData.lifeStatusOptions.first;

  String get batchFilter => _batchFilter;
  String get lifeFilter => _lifeFilter;

  static const _pageSize = 10;
  int _currentPage = 1;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get displayTotal => MockCrabData.totalPopulation;

  List<CrabIndividual> get filteredCrabs {
    var list = _crabs;
    if (_batchFilter != 'Tất cả lứa') {
      list = list.where((c) => c.batchId == _batchFilter).toList();
    }
    if (_lifeFilter != 'Tất cả trạng thái') {
      list = list
          .where((c) => c.lifeStatus.label == _lifeFilter)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (c) =>
                c.id.toLowerCase().contains(q) ||
                c.boxId.toLowerCase().contains(q) ||
                c.batchId.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  List<CrabIndividual> get paginatedCrabs {
    final list = filteredCrabs;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= list.length) return [];
    final end = (start + _pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int get filteredCount => filteredCrabs.length;

  int get totalPages => (filteredCount / _pageSize).ceil().clamp(1, 999);

  void setSearch(String query) {
    _searchQuery = query;
    _currentPage = 1;
    notifyListeners();
  }

  void setBatchFilter(String value) {
    _batchFilter = value;
    _currentPage = 1;
    notifyListeners();
  }

  void setLifeFilter(String value) {
    _lifeFilter = value;
    _currentPage = 1;
    notifyListeners();
  }

  void goToPage(int page) {
    _currentPage = page.clamp(1, totalPages);
    notifyListeners();
  }

  CrabIndividual? getById(String id) => MockCrabData.findById(_crabs, id);

  void updateCrab(CrabIndividual crab) {
    final i = _crabs.indexWhere((c) => c.id == crab.id);
    if (i >= 0) {
      _crabs = [..._crabs]..[i] = crab;
      notifyListeners();
    }
  }

  void addCrab(CrabIndividual crab) {
    _crabs = [crab, ..._crabs];
    _currentPage = 1;
    notifyListeners();
  }

  String generateNextId(String boxId) {
    final prefix = 'CRAB-$boxId-';
    var n = _crabs.where((c) => c.boxId == boxId).length + 1;
    var id = '$prefix${n.toString().padLeft(3, '0')}';
    while (_crabs.any((c) => c.id == id)) {
      n++;
      id = '$prefix${n.toString().padLeft(3, '0')}';
    }
    return id;
  }

  void updateWeight(
    String id, {
    required double weightGram,
    required double shellSizeCm,
    required DateTime measuredAt,
    String? note,
  }) {
    final crab = getById(id);
    if (crab == null) return;
    final history = [
      ...crab.weightHistory,
      CrabWeightPoint(
        date: measuredAt,
        weightGram: weightGram,
        shellSizeCm: shellSizeCm,
      ),
    ];
    updateCrab(
      crab.copyWith(
        weightGram: weightGram,
        shellSizeCm: shellSizeCm,
        weightHistory: history,
        quickNote: note?.isNotEmpty == true ? note! : crab.quickNote,
      ),
    );
  }

  void recordMolt(
    String id, {
    required DateTime date,
    required MoltCondition condition,
    String? note,
  }) {
    final crab = getById(id);
    if (crab == null) return;
    final n = crab.moltCount + 1;
    final molts = [
      ...crab.molts,
      CrabMoltRecord(number: n, date: date, condition: condition, note: note),
    ];
    final health = condition == MoltCondition.needsWatch
        ? CrabHealthStatus.monitoring
        : CrabHealthStatus.molting;
    updateCrab(
      crab.copyWith(
        moltCount: n,
        lastMoltDate: date,
        molts: molts,
        healthStatus: health,
      ),
    );
  }

  void recordDisease(
    String id, {
    required String name,
    required DiseaseSeverity severity,
    required String symptoms,
    required String treatment,
    required DateTime date,
  }) {
    final crab = getById(id);
    if (crab == null) return;
    updateCrab(
      crab.copyWith(
        diseases: [
          ...crab.diseases,
          CrabDiseaseRecord(
            date: date,
            name: name,
            severity: severity,
            symptoms: symptoms,
            treatment: treatment,
            status: DiseaseRecordStatus.monitoring,
          ),
        ],
        healthStatus: CrabHealthStatus.monitoring,
        healthScore: (crab.healthScore - 5).clamp(40, 100),
      ),
    );
  }

  void updateHealthStatus(String id, CrabHealthStatus status) {
    final crab = getById(id);
    if (crab == null) return;
    updateCrab(crab.copyWith(healthStatus: status));
  }

  void markReadyForSale(String id) {
    final crab = getById(id);
    if (crab == null) return;
    updateCrab(
      crab.copyWith(
        lifeStatus: CrabLifeStatus.readyForSale,
        healthStatus: CrabHealthStatus.good,
      ),
    );
  }

  void markDead(String id, {required String cause, required DateTime date}) {
    final crab = getById(id);
    if (crab == null) return;
    updateCrab(
      crab.copyWith(
        lifeStatus: CrabLifeStatus.dead,
        healthStatus: CrabHealthStatus.atRisk,
        healthScore: 0,
        quickNote: 'Đã chết ($cause) — ${MockCrabData.formatDate(date)}',
      ),
    );
  }
}
