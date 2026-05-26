import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

enum IotDeviceType {
  pump,
  drumFilter,
  skimmer,
  airPump,
  uv,
  fan,
  feeder,
  valve,
  other;

  String get filterLabel => switch (this) {
        IotDeviceType.pump => 'Máy bơm',
        IotDeviceType.drumFilter => 'Drum Filter',
        IotDeviceType.skimmer => 'Skimmer',
        IotDeviceType.airPump => 'Oxy',
        IotDeviceType.uv => 'UV',
        IotDeviceType.fan => 'Fan',
        IotDeviceType.feeder => 'Feeder',
        IotDeviceType.valve => 'Valve',
        IotDeviceType.other => 'Khác',
      };

  String get label => switch (this) {
        IotDeviceType.pump => 'Pump',
        IotDeviceType.drumFilter => 'Drum',
        IotDeviceType.skimmer => 'Skimmer',
        IotDeviceType.airPump => 'Oxy',
        IotDeviceType.uv => 'UV',
        IotDeviceType.fan => 'Fan',
        IotDeviceType.feeder => 'Feeder',
        IotDeviceType.valve => 'Valve',
        IotDeviceType.other => 'Khác',
      };

  IconData get icon => switch (this) {
        IotDeviceType.pump => Icons.water_outlined,
        IotDeviceType.drumFilter => Icons.filter_alt_outlined,
        IotDeviceType.skimmer => Icons.bubble_chart_outlined,
        IotDeviceType.airPump => Icons.air_outlined,
        IotDeviceType.uv => Icons.lightbulb_outline,
        IotDeviceType.fan => Icons.toys_outlined,
        IotDeviceType.feeder => Icons.restaurant_outlined,
        IotDeviceType.valve => Icons.settings_input_component_outlined,
        IotDeviceType.other => Icons.devices_other_outlined,
      };
}

enum IotConnectionStatus {
  online,
  offline;

  String get label => switch (this) {
        IotConnectionStatus.online => 'ONLINE',
        IotConnectionStatus.offline => 'OFFLINE',
      };

  String get labelVi => switch (this) {
        IotConnectionStatus.online => 'Trực tuyến',
        IotConnectionStatus.offline => 'Ngoại tuyến',
      };

  Color get color => switch (this) {
        IotConnectionStatus.online => DashboardColors.healthy,
        IotConnectionStatus.offline => DashboardColors.dead,
      };
}

enum IotRunStatus {
  running,
  stopped,
  maintenance,
  warning,
  error;

  String get label => switch (this) {
        IotRunStatus.running => 'Running',
        IotRunStatus.stopped => 'Stopped',
        IotRunStatus.maintenance => 'Bảo trì',
        IotRunStatus.warning => 'Cảnh báo',
        IotRunStatus.error => 'Lỗi',
      };

  String get labelVi => switch (this) {
        IotRunStatus.running => 'Đang hoạt động',
        IotRunStatus.stopped => 'Đang dừng',
        IotRunStatus.maintenance => 'Bảo trì',
        IotRunStatus.warning => 'Cảnh báo',
        IotRunStatus.error => 'Có lỗi',
      };

  Color get color => switch (this) {
        IotRunStatus.running => DashboardColors.blue,
        IotRunStatus.stopped => DashboardColors.dead,
        IotRunStatus.maintenance => DashboardColors.monitoring,
        IotRunStatus.warning => DashboardColors.molting,
        IotRunStatus.error => DashboardColors.risk,
      };
}

enum IotControlMode { auto, manual }

extension IotControlModeX on IotControlMode {
  String get label => name.toUpperCase();

  String get modeButtonLabel => switch (this) {
        IotControlMode.auto => 'CHẾ ĐỘ: TỰ ĐỘNG',
        IotControlMode.manual => 'CHẾ ĐỘ: THỦ CÔNG',
      };
}

class IotDeviceKpi {
  const IotDeviceKpi({
    required this.online,
    required this.offline,
    required this.running,
    required this.error,
  });

  final int online;
  final int offline;
  final int running;
  final int error;
}

class IotDeviceOverview {
  const IotDeviceOverview({
    required this.total,
    required this.online,
    required this.offline,
    required this.running,
    required this.stopped,
    required this.error,
    required this.energyTodayKwh,
  });

  final int total;
  final int online;
  final int offline;
  final int running;
  final int stopped;
  final int error;
  final double energyTodayKwh;
}

class IotDeviceDetailMeta {
  const IotDeviceDetailMeta({
    required this.deviceCode,
    required this.firmware,
    required this.ip,
    required this.mqttStatus,
    required this.lastSeen,
  });

  final String deviceCode;
  final String firmware;
  final String ip;
  final String mqttStatus;
  final String lastSeen;
}

class IotDevice {
  const IotDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    required this.location,
    required this.connection,
    required this.runStatus,
    required this.mode,
    required this.isOn,
    required this.powerWatts,
    required this.runCount,
    required this.scheduleInfo,
    required this.meta,
    this.lastRunTime = '',
    this.errorMessage,
    this.hasNoError = true,
    this.showFixNow = false,
    this.showTestButton = false,
    this.flowRate,
    this.doCurrent,
    this.doTarget,
    this.valveOpenPercent,
    this.fanSpeedPercent,
    this.envTemp,
    this.fanThreshold,
    this.feedPortionG,
    this.feedsToday = 0,
    this.feedSchedule = const [],
    this.uvHoursPerDay,
    this.uvLifespanHours,
    this.skimmerEfficiency,
    this.lastWashTime,
    this.cycleMinutes,
    this.totalWashes = 0,
    this.valveCycleCount = 0,
  });

  final String id;
  final String name;
  final IotDeviceType type;
  final String typeLabel;
  final String location;
  final IotConnectionStatus connection;
  final IotRunStatus runStatus;
  final IotControlMode mode;
  final bool isOn;
  final int powerWatts;
  final int runCount;
  final String scheduleInfo;
  final IotDeviceDetailMeta meta;
  final String lastRunTime;
  final String? errorMessage;
  final bool hasNoError;
  final bool showFixNow;
  final bool showTestButton;
  final String? flowRate;
  final double? doCurrent;
  final double? doTarget;
  final int? valveOpenPercent;
  final int? fanSpeedPercent;
  final double? envTemp;
  final double? fanThreshold;
  final int? feedPortionG;
  final int feedsToday;
  final List<String> feedSchedule;
  final int? uvHoursPerDay;
  final int? uvLifespanHours;
  final int? skimmerEfficiency;
  final String? lastWashTime;
  final int? cycleMinutes;
  final int totalWashes;
  final int valveCycleCount;

  bool get isRunning =>
      runStatus == IotRunStatus.running &&
      connection == IotConnectionStatus.online &&
      isOn;

  bool get canControl =>
      connection == IotConnectionStatus.online && !hasBlockingError;

  bool get hasBlockingError =>
      errorMessage != null &&
      (runStatus == IotRunStatus.error || runStatus == IotRunStatus.warning);
}

class IotActivityLog {
  const IotActivityLog({
    required this.time,
    required this.deviceName,
    required this.action,
    required this.success,
  });

  final String time;
  final String deviceName;
  final String action;
  final bool success;
}

class IotAutomationRule {
  IotAutomationRule({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
  });

  final String id;
  final String title;
  final String description;
  bool enabled;
}

class IotDeviceStats {
  const IotDeviceStats({
    required this.totalRuntimeHours,
    required this.totalEnergyKwh,
    required this.powerOnCount,
    required this.errorCount,
    required this.efficiencyPercent,
  });

  final int totalRuntimeHours;
  final int totalEnergyKwh;
  final int powerOnCount;
  final int errorCount;
  final int efficiencyPercent;
}

class IotScheduleEntry {
  const IotScheduleEntry({required this.time, required this.action});

  final String time;
  final String action;
}

class IotCalendarBlock {
  const IotCalendarBlock({required this.range, required this.label});

  final String range;
  final String label;
}

class IotDeviceAlert {
  const IotDeviceAlert({
    required this.message,
    required this.severity,
    this.deviceName = '',
  });

  final String message;
  final String deviceName;
  final IotRunStatus severity;
}
