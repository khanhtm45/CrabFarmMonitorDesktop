import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum CrabGender {
  male,
  female;

  String get label => switch (this) {
        CrabGender.male => 'Đực',
        CrabGender.female => 'Cái',
      };
}

enum CrabHealthStatus {
  healthy,
  good,
  monitoring,
  molting,
  atRisk;

  String get label => switch (this) {
        CrabHealthStatus.healthy => 'Khỏe mạnh',
        CrabHealthStatus.good => 'Tốt',
        CrabHealthStatus.monitoring => 'Theo dõi',
        CrabHealthStatus.molting => 'Đang lột xác',
        CrabHealthStatus.atRisk => 'Nguy cơ',
      };

  Color get color => switch (this) {
        CrabHealthStatus.healthy => DashboardColors.healthy,
        CrabHealthStatus.good => DashboardColors.cyan,
        CrabHealthStatus.monitoring => DashboardColors.monitoring,
        CrabHealthStatus.molting => DashboardColors.molting,
        CrabHealthStatus.atRisk => DashboardColors.risk,
      };
}

enum CrabLifeStatus {
  raising,
  readyForSale,
  sold,
  dead;

  String get label => switch (this) {
        CrabLifeStatus.raising => 'Đang nuôi',
        CrabLifeStatus.readyForSale => 'Sẵn sàng bán',
        CrabLifeStatus.sold => 'Đã bán',
        CrabLifeStatus.dead => 'Đã chết',
      };

  Color get color => switch (this) {
        CrabLifeStatus.raising => DashboardColors.cyan,
        CrabLifeStatus.readyForSale => DashboardColors.blue,
        CrabLifeStatus.sold => DashboardColors.purple,
        CrabLifeStatus.dead => DashboardColors.dead,
      };
}

enum MoltCondition {
  normal,
  weak,
  needsWatch;

  String get label => switch (this) {
        MoltCondition.normal => 'Bình thường',
        MoltCondition.weak => 'Yếu',
        MoltCondition.needsWatch => 'Cần theo dõi',
      };
}

enum DiseaseSeverity {
  mild,
  moderate,
  severe;

  String get label => switch (this) {
        DiseaseSeverity.mild => 'Nhẹ',
        DiseaseSeverity.moderate => 'Trung bình',
        DiseaseSeverity.severe => 'Nặng',
      };
}

enum DiseaseRecordStatus {
  resolved,
  monitoring,
  active;

  String get label => switch (this) {
        DiseaseRecordStatus.resolved => 'Đã xử lý',
        DiseaseRecordStatus.monitoring => 'Theo dõi',
        DiseaseRecordStatus.active => 'Đang xử lý',
      };
}
