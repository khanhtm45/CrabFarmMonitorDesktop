import 'package:flutter/material.dart';

import '../models/box_status.dart';
import '../models/crab_box.dart';

class FarmLayoutSummary {
  const FarmLayoutSummary({
    required this.total,
    required this.occupied,
    required this.empty,
    required this.normal,
    required this.watch,
    required this.molting,
    required this.alert,
    required this.deceased,
  });

  final int total;
  final int occupied;
  final int empty;
  final int normal;
  final int watch;
  final int molting;
  final int alert;
  final int deceased;
}

abstract final class MockFarmLayoutData {
  static const zones = ['A', 'B', 'C'];
  static const boxesPerZone = 120;
  static const columnsPerRow = 10;

  static const rasFlow = [
    RasComponent(
      name: 'Ao tuần hoàn',
      metric: '24.5 m³',
      icon: Icons.water,
    ),
    RasComponent(
      name: 'Drum Filter',
      metric: '1200 L/h',
      icon: Icons.filter_alt_outlined,
    ),
    RasComponent(
      name: 'Bio Filter',
      metric: 'pH 8.1',
      icon: Icons.biotech_outlined,
    ),
    RasComponent(
      name: 'Skimmer',
      metric: '88% Eff.',
      icon: Icons.air_outlined,
    ),
    RasComponent(
      name: 'Bể chứa',
      metric: '18.2 m³',
      icon: Icons.storage_outlined,
    ),
    RasComponent(
      name: 'Máy bơm',
      metric: '2.4 kW',
      icon: Icons.settings_input_component_outlined,
    ),
    RasComponent(
      name: 'Hộp nuôi cua',
      metric: '360 hộp',
      icon: Icons.grid_view,
    ),
  ];

  static List<CrabBox> generateBoxes() {
    final statuses = <BoxStatus>[
      ...List.filled(280, BoxStatus.normal),
      ...List.filled(25, BoxStatus.watch),
      ...List.filled(10, BoxStatus.molting),
      ...List.filled(4, BoxStatus.alert),
      ...List.filled(1, BoxStatus.deceased),
      ...List.filled(40, BoxStatus.empty),
    ];

  final boxes = <CrabBox>[];
    var statusIndex = 0;

    for (final zone in zones) {
      for (var i = 1; i <= boxesPerZone; i++) {
        final id = '$zone${i.toString().padLeft(2, '0')}';
        final status = statuses[statusIndex++];

        boxes.add(_boxFromStatus(id, zone, status));
      }
    }

    _assignShowcaseBoxes(boxes);
    return boxes;
  }

  static void _assignShowcaseBoxes(List<CrabBox> boxes) {
    final showcase = {
      'A01': BoxStatus.normal,
      'A02': BoxStatus.watch,
      'A03': BoxStatus.molting,
      'A04': BoxStatus.alert,
      'A05': BoxStatus.deceased,
      'A06': BoxStatus.empty,
      'A07': BoxStatus.alert,
    };

    for (var i = 0; i < boxes.length; i++) {
      final s = showcase[boxes[i].id];
      if (s != null) {
        boxes[i] = _boxFromStatus(boxes[i].id, boxes[i].zone, s);
      }
    }
  }

  static CrabBox _boxFromStatus(String id, String zone, BoxStatus status) {
    if (status == BoxStatus.empty) {
      return CrabBox(id: id, zone: zone, status: status);
    }

    final health = switch (status) {
      BoxStatus.normal => 94,
      BoxStatus.watch => 78,
      BoxStatus.molting => 85,
      BoxStatus.alert => 62,
      BoxStatus.deceased => 0,
      BoxStatus.empty => 0,
    };

    return CrabBox(
      id: id,
      zone: zone,
      status: status,
      healthScore: health,
      crabId: 'CRAB-$id-001',
      batchId: 'CFM-2026-001',
      releaseDate: DateTime(2026, 1, 1),
      weightGram: 125,
      lastMoltDate: DateTime(2026, 2, 12),
      expectedHarvest: DateTime(2026, 3, 20),
      hasAlert: status == BoxStatus.alert,
    );
  }

  static FarmLayoutSummary summarize(List<CrabBox> boxes) {
    return FarmLayoutSummary(
      total: boxes.length,
      occupied: boxes.where((b) => b.isOccupied).length,
      empty: boxes.where((b) => b.status == BoxStatus.empty).length,
      normal: boxes.where((b) => b.status == BoxStatus.normal).length,
      watch: boxes.where((b) => b.status == BoxStatus.watch).length,
      molting: boxes.where((b) => b.status == BoxStatus.molting).length,
      alert: boxes.where((b) => b.status == BoxStatus.alert).length,
      deceased: boxes.where((b) => b.status == BoxStatus.deceased).length,
    );
  }

  static List<MapEntry<String, String>> boxEnvironment() => const [
        MapEntry('Nhiệt độ', '28.4°C'),
        MapEntry('pH', '7.8'),
        MapEntry('DO', '6.5 mg/L'),
        MapEntry('Độ mặn', '15 ppt'),
        MapEntry('NH3', '0.02 mg/L'),
        MapEntry('NO2', '0.01 mg/L'),
      ];

  static List<String> boxActivityLog() => const [
        '08:00 - Cho ăn',
        '10:30 - Kiểm tra cảm biến',
        '12:00 - Cua hoạt động bình thường',
        '15:20 - Ghi nhận tăng trưởng',
      ];

  static String mascotMessage(List<CrabBox> boxes) {
    final alerts = boxes.where((b) => b.status == BoxStatus.alert).toList();
    if (alerts.isEmpty) {
      return 'Hệ thống RAS đang hoạt động ổn định.\nKhông có hộp cần xử lý khẩn cấp.';
    }
    final ids = alerts.take(2).map((b) => b.id).join(', ');
    return 'Hệ thống RAS đang hoạt động ổn định.\n'
        'Lưu ý Hộp $ids cần kiểm tra khẩn cấp vì nồng độ DO thấp!';
  }
}
