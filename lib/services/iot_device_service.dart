import 'package:flutter/foundation.dart';

import '../data/mock_iot_devices_data.dart';
import '../models/iot_device.dart';

class IotDeviceService extends ChangeNotifier {
  final List<IotDevice> _devices =
      List.of(MockIotDevicesData.devices(), growable: true);
  final List<IotAutomationRule> _rules =
      List.of(MockIotDevicesData.automationRules(), growable: true);

  String _category = 'Tất cả';
  String _search = '';
  String? _selectedId = 'pump-01';
  bool _emergencyStop = false;

  IotDeviceKpi get kpi => MockIotDevicesData.kpi;
  IotDeviceOverview get overview => MockIotDevicesData.overview;

  List<IotAutomationRule> get rules => List.unmodifiable(_rules);
  List<IotActivityLog> get activityLogs => MockIotDevicesData.activityLogs();
  IotDeviceStats get stats => MockIotDevicesData.deviceStats;
  List<IotScheduleEntry> get schedule => MockIotDevicesData.defaultSchedule();
  List<IotCalendarBlock> get calendarBlocks =>
      MockIotDevicesData.calendarBlocks();
  List<IotDeviceAlert> get alerts => MockIotDevicesData.systemAlerts();

  String get aiInsight => MockIotDevicesData.aiInsight;
  String get aiRecommendation => MockIotDevicesData.aiRecommendation;
  int get coreCpuPercent => MockIotDevicesData.coreCpuPercent;
  int get zigbeeSignalPercent => MockIotDevicesData.zigbeeSignalPercent;

  String get category => _category;
  bool get emergencyStop => _emergencyStop;

  IotDevice? get selectedDevice {
    if (_selectedId == null) return null;
    try {
      return _devices.firstWhere((d) => d.id == _selectedId);
    } catch (_) {
      return _devices.isNotEmpty ? _devices.first : null;
    }
  }

  List<IotDevice> get filteredDevices {
    var list = _devices;
    if (_category != 'Tất cả') {
      list = list.where((d) => d.type.filterLabel == _category).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (d) =>
                d.name.toLowerCase().contains(q) ||
                d.typeLabel.toLowerCase().contains(q) ||
                d.location.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setCategory(String v) {
    _category = v;
    notifyListeners();
  }

  void selectDevice(String id) {
    _selectedId = id;
    notifyListeners();
  }

  void togglePower(String id) {
    _updateDevice(id, (d) {
      if (!d.canControl && d.connection == IotConnectionStatus.offline) {
        return d;
      }
      final on = !d.isOn;
      return _copy(
        d,
        isOn: on,
        runStatus: on ? IotRunStatus.running : IotRunStatus.stopped,
        powerWatts: on ? _defaultPower(d) : 0,
      );
    });
  }

  void toggleMode(String id) {
    final i = _devices.indexWhere((d) => d.id == id);
    if (i < 0) return;
    final d = _devices[i];
    setMode(
      id,
      d.mode == IotControlMode.auto ? IotControlMode.manual : IotControlMode.auto,
    );
  }

  void setMode(String id, IotControlMode mode) {
    _updateDevice(id, (d) => _copy(d, mode: mode));
  }

  void triggerWash(String id) {
    _updateDevice(id, (d) => _copy(d, lastWashTime: 'Vừa xong'));
    notifyListeners();
  }

  void feedNow(String id) {
    _updateDevice(id, (d) => _copy(d, feedsToday: d.feedsToday + 1));
    notifyListeners();
  }

  void testDevice(String id) {
    _updateDevice(
      id,
      (d) => _copy(d, runStatus: IotRunStatus.running, isOn: true),
    );
  }

  void fixNow(String id) {
    _updateDevice(
      id,
      (d) => _copy(d, showFixNow: false, hasNoError: true),
    );
  }

  void setValveOpen(String id, int percent) {
    _updateDevice(
      id,
      (d) => _copy(
        d,
        valveOpenPercent: percent,
        isOn: percent > 0,
        runStatus: percent > 0 ? IotRunStatus.running : IotRunStatus.stopped,
      ),
    );
  }

  void setFanSpeed(String id, int percent) {
    _updateDevice(id, (d) => _copy(d, fanSpeedPercent: percent));
  }

  void toggleRule(String ruleId) {
    final i = _rules.indexWhere((r) => r.id == ruleId);
    if (i >= 0) {
      _rules[i].enabled = !_rules[i].enabled;
      notifyListeners();
    }
  }

  void emergencyStopAll() {
    _emergencyStop = true;
    for (var i = 0; i < _devices.length; i++) {
      final d = _devices[i];
      if (d.connection == IotConnectionStatus.online) {
        _devices[i] = _copy(
          d,
          isOn: false,
          runStatus: IotRunStatus.stopped,
          powerWatts: 0,
        );
      }
    }
    notifyListeners();
  }

  void resetEmergency() {
    _emergencyStop = false;
    notifyListeners();
  }

  int _defaultPower(IotDevice d) {
    if (d.powerWatts > 0) return d.powerWatts;
    return switch (d.type) {
      IotDeviceType.pump => 450,
      IotDeviceType.drumFilter => 250,
      IotDeviceType.skimmer => 120,
      IotDeviceType.airPump => 75,
      IotDeviceType.uv => 40,
      IotDeviceType.fan => 80,
      IotDeviceType.feeder => 25,
      _ => 15,
    };
  }

  void _updateDevice(String id, IotDevice Function(IotDevice) transform) {
    final i = _devices.indexWhere((d) => d.id == id);
    if (i >= 0) {
      _devices[i] = transform(_devices[i]);
      notifyListeners();
    }
  }

  IotDevice _copy(
    IotDevice d, {
    bool? isOn,
    IotRunStatus? runStatus,
    IotControlMode? mode,
    int? powerWatts,
    String? lastWashTime,
    int? feedsToday,
    int? valveOpenPercent,
    int? fanSpeedPercent,
    bool? showFixNow,
    bool? hasNoError,
  }) {
    return IotDevice(
      id: d.id,
      name: d.name,
      type: d.type,
      typeLabel: d.typeLabel,
      location: d.location,
      connection: d.connection,
      runStatus: runStatus ?? d.runStatus,
      mode: mode ?? d.mode,
      isOn: isOn ?? d.isOn,
      powerWatts: powerWatts ?? d.powerWatts,
      runCount: d.runCount,
      scheduleInfo: d.scheduleInfo,
      meta: d.meta,
      lastRunTime: d.lastRunTime,
      errorMessage: d.errorMessage,
      hasNoError: hasNoError ?? d.hasNoError,
      showFixNow: showFixNow ?? d.showFixNow,
      showTestButton: d.showTestButton,
      flowRate: d.flowRate,
      doCurrent: d.doCurrent,
      doTarget: d.doTarget,
      valveOpenPercent: valveOpenPercent ?? d.valveOpenPercent,
      fanSpeedPercent: fanSpeedPercent ?? d.fanSpeedPercent,
      envTemp: d.envTemp,
      fanThreshold: d.fanThreshold,
      feedPortionG: d.feedPortionG,
      feedsToday: feedsToday ?? d.feedsToday,
      feedSchedule: d.feedSchedule,
      uvHoursPerDay: d.uvHoursPerDay,
      uvLifespanHours: d.uvLifespanHours,
      skimmerEfficiency: d.skimmerEfficiency,
      lastWashTime: lastWashTime ?? d.lastWashTime,
      cycleMinutes: d.cycleMinutes,
      totalWashes: d.totalWashes,
      valveCycleCount: d.valveCycleCount,
    );
  }
}
