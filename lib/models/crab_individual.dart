import 'package:flutter/material.dart';

import 'crab_status.dart';

class CrabMoltRecord {
  const CrabMoltRecord({
    required this.number,
    required this.date,
    required this.condition,
    this.note,
  });

  final int number;
  final DateTime date;
  final MoltCondition condition;
  final String? note;
}

class CrabDiseaseRecord {
  const CrabDiseaseRecord({
    required this.date,
    required this.name,
    required this.severity,
    required this.symptoms,
    required this.treatment,
    required this.status,
  });

  final DateTime date;
  final String name;
  final DiseaseSeverity severity;
  final String symptoms;
  final String treatment;
  final DiseaseRecordStatus status;
}

class CrabFeedingRecord {
  const CrabFeedingRecord({
    required this.date,
    required this.foodType,
    required this.amountGram,
    this.note,
  });

  final DateTime date;
  final String foodType;
  final double amountGram;
  final String? note;
}

class CrabWeightPoint {
  const CrabWeightPoint({
    required this.date,
    required this.weightGram,
    this.shellSizeCm,
  });

  final DateTime date;
  final double weightGram;
  final double? shellSizeCm;
}

class CrabIndividual {
  const CrabIndividual({
    required this.id,
    required this.boxId,
    required this.batchId,
    required this.gender,
    required this.weightGram,
    required this.shellSizeCm,
    required this.releaseDate,
    required this.moltCount,
    required this.healthStatus,
    required this.lifeStatus,
    required this.healthScore,
    this.lastMoltDate,
    this.quickNote = '',
    this.molts = const [],
    this.diseases = const [],
    this.feedings = const [],
    this.weightHistory = const [],
    this.envTempC = 28.5,
    this.envSalinityPpt = 25,
  });

  final String id;
  final String boxId;
  final String batchId;
  final CrabGender gender;
  final double weightGram;
  final double shellSizeCm;
  final DateTime releaseDate;
  final int moltCount;
  final DateTime? lastMoltDate;
  final CrabHealthStatus healthStatus;
  final CrabLifeStatus lifeStatus;
  final int healthScore;
  final String quickNote;
  final List<CrabMoltRecord> molts;
  final List<CrabDiseaseRecord> diseases;
  final List<CrabFeedingRecord> feedings;
  final List<CrabWeightPoint> weightHistory;
  final double envTempC;
  final double envSalinityPpt;

  int get ageDays => DateTime.now().difference(releaseDate).inDays;

  int? get daysSinceLastMolt => lastMoltDate == null
      ? null
      : DateTime.now().difference(lastMoltDate!).inDays;

  double get growthLast7Days {
    if (weightHistory.length < 2) return 0;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    CrabWeightPoint? past;
    for (final p in weightHistory) {
      if (!p.date.isAfter(weekAgo)) past = p;
    }
    past ??= weightHistory.first;
    return weightGram - past.weightGram;
  }

  double get avgFeedingGram {
    if (feedings.isEmpty) return 0;
    final total = feedings.fold<double>(0, (s, f) => s + f.amountGram);
    return total / feedings.length;
  }

  bool get canMarkReadyForSale =>
      lifeStatus != CrabLifeStatus.dead &&
      lifeStatus != CrabLifeStatus.sold &&
      weightGram >= 150 &&
      healthScore >= 85 &&
      !diseases.any(
        (d) =>
            d.status != DiseaseRecordStatus.resolved &&
            DateTime.now().difference(d.date).inDays <= 7,
      ) &&
      (daysSinceLastMolt == null || daysSinceLastMolt! >= 3);

  CrabIndividual copyWith({
    String? id,
    String? boxId,
    String? batchId,
    CrabGender? gender,
    double? weightGram,
    double? shellSizeCm,
    DateTime? releaseDate,
    int? moltCount,
    DateTime? lastMoltDate,
    CrabHealthStatus? healthStatus,
    CrabLifeStatus? lifeStatus,
    int? healthScore,
    String? quickNote,
    List<CrabMoltRecord>? molts,
    List<CrabDiseaseRecord>? diseases,
    List<CrabFeedingRecord>? feedings,
    List<CrabWeightPoint>? weightHistory,
    double? envTempC,
    double? envSalinityPpt,
  }) {
    return CrabIndividual(
      id: id ?? this.id,
      boxId: boxId ?? this.boxId,
      batchId: batchId ?? this.batchId,
      gender: gender ?? this.gender,
      weightGram: weightGram ?? this.weightGram,
      shellSizeCm: shellSizeCm ?? this.shellSizeCm,
      releaseDate: releaseDate ?? this.releaseDate,
      moltCount: moltCount ?? this.moltCount,
      lastMoltDate: lastMoltDate ?? this.lastMoltDate,
      healthStatus: healthStatus ?? this.healthStatus,
      lifeStatus: lifeStatus ?? this.lifeStatus,
      healthScore: healthScore ?? this.healthScore,
      quickNote: quickNote ?? this.quickNote,
      molts: molts ?? this.molts,
      diseases: diseases ?? this.diseases,
      feedings: feedings ?? this.feedings,
      weightHistory: weightHistory ?? this.weightHistory,
      envTempC: envTempC ?? this.envTempC,
      envSalinityPpt: envSalinityPpt ?? this.envSalinityPpt,
    );
  }
}

class CrabSummaryKpi {
  const CrabSummaryKpi({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.accentColor,
    this.showProgress = false,
    this.progress,
  });

  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color accentColor;
  final bool showProgress;
  final double? progress;
}
