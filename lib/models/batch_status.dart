import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum BatchStatus {
  raising,
  readyHarvest,
  harvested,
  incident,
  ended,
}

extension BatchStatusX on BatchStatus {
  String get label => switch (this) {
        BatchStatus.raising => 'Đang nuôi',
        BatchStatus.readyHarvest => 'Sắp thu hoạch',
        BatchStatus.harvested => 'Đã thu hoạch',
        BatchStatus.incident => 'Có sự cố',
        BatchStatus.ended => 'Đã kết thúc',
      };

  Color get color => switch (this) {
        BatchStatus.raising => DashboardColors.healthy,
        BatchStatus.readyHarvest => DashboardColors.monitoring,
        BatchStatus.harvested => DashboardColors.blue,
        BatchStatus.incident => DashboardColors.risk,
        BatchStatus.ended => DashboardColors.dead,
      };

  String get emoji => switch (this) {
        BatchStatus.raising => '🟢',
        BatchStatus.readyHarvest => '🟡',
        BatchStatus.harvested => '🔵',
        BatchStatus.incident => '🔴',
        BatchStatus.ended => '⚫',
      };
}
