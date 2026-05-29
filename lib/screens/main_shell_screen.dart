import 'package:flutter/material.dart';

import '../data/mock_dashboard_data.dart';
import '../models/crab_batch.dart';
import '../models/crab_individual.dart';
import '../models/device_setup.dart';
import '../navigation/app_route.dart';
import '../services/batch_service.dart';
import '../services/crab_service.dart';
import '../widgets/dashboard/app_sidebar.dart';
import '../widgets/dashboard/wave_background.dart';
import '../widgets/shared/app_footer.dart';
import '../widgets/shared/app_top_bar.dart';
import 'batch/batch_detail_page.dart';
import 'batch/batch_list_page.dart';
import 'crab/crab_detail_page.dart';
import 'crab/crab_list_page.dart';
import 'dashboard_screen.dart';
import 'farm/farm_layout_page.dart';
import 'farm/farm_management_page.dart';
import 'area/area_detail_page.dart';
import 'area/area_management_page.dart';
import 'production/production_entity_page.dart';
import '../services/area_management_service.dart';
import 'health/health_monitoring_page.dart';
import 'camera/camera_ai_page.dart';
import 'environment/water_quality_page.dart';
import 'devices/iot_control_page.dart';
import 'alerts/alert_system_page.dart';
import 'logs/farm_activity_log_page.dart';
import 'feed/feed_management_page.dart';
import 'harvest/harvest_sales_page.dart';
import 'reports/farm_report_page.dart';
import 'ai/ai_insight_page.dart';
import 'sensor/sensor_upgrade_page.dart';
import 'device_setup/device_setup_page.dart';
import '../services/camera_ai_service.dart';
import '../services/water_quality_service.dart';
import '../services/iot_device_service.dart';
import '../services/alert_service.dart';
import '../services/farm_management_service.dart';
import '../services/production_management_service.dart';
import '../services/farm_log_service.dart';
import '../services/feed_service.dart';
import '../services/harvest_sales_service.dart';
import '../services/farm_report_service.dart';
import '../services/ai_assistant_service.dart';
import '../services/sensor_kit_service.dart';
import '../services/device_setup_service.dart';
import '../models/auth_models.dart';
import '../services/cloud_api_client.dart';
import '../services/connectivity_link_service.dart';
import '../services/theme_mode_service.dart';
import 'login_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.session,
  });

  final AuthSession session;

  String get email => session.user.email;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late AuthSession _session;
  final _cloudApi = CloudApiClient();
  final _batchService = BatchService();
  final _crabService = CrabService();
  final _cameraAiService = CameraAiService();
  late final WaterQualityService _waterQualityService;
  late final FarmManagementService _farmManagementService;
  late final ProductionManagementService _productionManagementService;
  late final AreaManagementService _areaManagementService;
  final _iotDeviceService = IotDeviceService();
  final _alertService = AlertService();
  final _farmLogService = FarmLogService();
  final _feedService = FeedService();
  final _harvestSalesService = HarvestSalesService();
  final _farmReportService = FarmReportService();
  final _aiAssistantService = AiAssistantService();
  final _sensorKitService = SensorKitService();
  final _deviceSetupService = DeviceSetupService();
  late final ConnectivityLinkService _connectivityLinkService;
  AppRoute _route = AppRoute.dashboard;
  CrabBatch? _selectedBatch;
  String? _selectedCrabId;
  String? _selectedAreaId;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _connectivityLinkService =
        ConnectivityLinkService(session: _session);
    _waterQualityService = WaterQualityService(session: _session);
    _farmManagementService = FarmManagementService(session: _session);
    _productionManagementService =
        ProductionManagementService(session: _session);
    _areaManagementService = AreaManagementService(session: _session);
    _connectivityLinkService.addListener(_onConnectivityUpdate);
    _connectivityLinkService.refreshCloud();
    if (_session.isOrgAdmin) {
      _refreshAdminFarms();
    }
  }

  void _syncSessionFarmsFromRecords() {
    final summaries = _farmManagementService.farms
        .map((f) => f.toSummary())
        .toList();
    if (summaries.isEmpty) return;
    final selected = summaries.any((f) => f.id == _session.selectedFarm.id)
        ? _session.selectedFarm
        : summaries.first;
    setState(() {
      _session = _session.copyWith(farms: summaries, selectedFarm: selected);
    });
    _applySessionToServices();
  }

  void _applySessionToServices() {
    _connectivityLinkService.updateSession(_session);
    _waterQualityService.updateSession(_session);
    _farmManagementService.updateSession(_session);
    _productionManagementService.updateSession(_session);
    _areaManagementService.updateSession(_session);
  }

  Future<void> _refreshAdminFarms() async {
    try {
      final farms = await _cloudApi.fetchFarms(_session.token);
      if (!mounted || farms.isEmpty) return;
      final selected = farms.any((f) => f.id == _session.selectedFarm.id)
          ? _session.selectedFarm
          : farms.first;
      setState(() {
        _session = _session.copyWith(farms: farms, selectedFarm: selected);
      });
      _applySessionToServices();
    } catch (_) {
      // Giữ danh sách từ /api/auth/me nếu refresh thất bại.
    }
  }

  @override
  void dispose() {
    _connectivityLinkService.removeListener(_onConnectivityUpdate);
    super.dispose();
  }

  void _onConnectivityUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _onFarmChanged(FarmSummary farm) {
    if (farm.id == _session.selectedFarm.id) return;
    setState(() {
      _session = _session.copyWith(selectedFarm: farm);
    });
    _connectivityLinkService.updateSession(_session);
    _waterQualityService.updateSession(_session);
    if (_route.isProductionRoute) {
      _productionManagementService.loadCurrentTab();
    }
    if (_route == AppRoute.areaManagement || _route == AppRoute.areaDetail) {
      _areaManagementService.load();
    }
    _connectivityLinkService.refreshCloud();
    _waterQualityService.refreshTrend(quiet: true);
  }

  AppTopBar _shellTopBar({
    String? title,
    String searchHint = 'Tìm kiếm...',
    ValueChanged<String>? onSearchChanged,
    int alertCount = 5,
    Widget? leading,
    Widget? centerTitle,
  }) {
    return AppTopBar(
      title: title,
      searchHint: searchHint,
      onSearchChanged: onSearchChanged,
      displayName: _session.user.displayName,
      alertCount: alertCount,
      leading: leading,
      centerTitle: centerTitle,
      onLogout: _logout,
      connectivity: _connectivityLinkService,
      onOpenDeviceSetup: _openDeviceSetupCloudEdge,
      onSettingsTap: _openDeviceSetup,
      farms: _session.farms,
      selectedFarm: _session.selectedFarm,
      onFarmChanged: (_session.isOrgAdmin || _session.farms.length > 1)
          ? _onFarmChanged
          : null,
    );
  }

  void _navigate(AppRoute route) {
    setState(() {
      _route = route;
      if (route != AppRoute.batchDetail) {
        _selectedBatch = null;
      }
      if (route != AppRoute.individualDetail &&
          route != AppRoute.individualHealth) {
        _selectedCrabId = null;
      }
    });
    if (route.isProductionRoute) {
      _productionManagementService.setTab(productionTabForRoute(route));
      _productionManagementService.loadCurrentTab();
    }
    if (route == AppRoute.areaManagement) {
      _areaManagementService.load();
    }
    if (route != AppRoute.areaDetail) {
      _selectedAreaId = null;
    }
  }

  void _openAreaDetail(String areaId) {
    setState(() {
      _selectedAreaId = areaId;
      _route = AppRoute.areaDetail;
    });
  }

  void _backToAreaList() {
    setState(() {
      _route = AppRoute.areaManagement;
      _selectedAreaId = null;
    });
    _areaManagementService.load();
  }

  void _openBatchDetail(CrabBatch batch) {
    setState(() {
      _selectedBatch = batch;
      _selectedCrabId = null;
      _route = AppRoute.batchDetail;
    });
  }

  void _backToBatchList() {
    setState(() {
      _route = AppRoute.batches;
      _selectedBatch = null;
    });
  }

  void _openCrabDetail(CrabIndividual crab) {
    setState(() {
      _selectedCrabId = crab.id;
      _selectedBatch = null;
      _route = AppRoute.individualDetail;
    });
  }

  void _openHealthMonitoring(String crabId) {
    setState(() {
      _selectedCrabId = crabId;
      _selectedBatch = null;
      _route = AppRoute.individualHealth;
    });
  }

  void _backToCrabList() {
    setState(() {
      _route = AppRoute.individuals;
      _selectedCrabId = null;
    });
  }

  void _backToCrabDetail() {
    setState(() {
      _route = AppRoute.individualDetail;
    });
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appThemeMode,
      builder: (context, _) => _buildShell(context),
    );
  }

  Widget _buildShell(BuildContext context) {
    final sidebarRoute = switch (_route) {
      AppRoute.batchDetail => AppRoute.batches,
      AppRoute.individualDetail || AppRoute.individualHealth => AppRoute.individuals,
      AppRoute.areaDetail => AppRoute.areaManagement,
      _ => _route,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          WaveBackground(key: ValueKey(appThemeMode.isDark)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSidebar(
                selected: sidebarRoute,
                onSelect: _navigate,
                onLogout: _logout,
                onUpgradeSensorKit: () => _navigate(AppRoute.sensorUpgrade),
                onOpenDeviceSetup: () => _navigate(AppRoute.deviceSetup),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(child: _buildBody()),
                    const AppFooter(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openDeviceSetup() => _navigate(AppRoute.deviceSetup);

  void _openDeviceSetupCloudEdge() {
    _deviceSetupService.selectSection(DeviceSetupSection.cloudEdge);
    _navigate(AppRoute.deviceSetup);
  }

  Widget _buildTopBar() {
    if (_route == AppRoute.deviceSetup) {
      return _shellTopBar(
        title: 'Device Setup',
        searchHint: 'Tìm node ESP32...',
        centerTitle: const SizedBox.shrink(),
        leading: IconButton(
          onPressed: () => _navigate(AppRoute.dashboard),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
      );
    }

    if (_route == AppRoute.batchDetail && _selectedBatch != null) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm lứa nuôi, thiết bị...',
        leading: IconButton(
          onPressed: _backToBatchList,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.individualHealth && _selectedCrabId != null) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm cá thể, thiết bị hoặc khu nuôi...',
        leading: IconButton(
          onPressed: _backToCrabDetail,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.individualDetail && _selectedCrabId != null) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm cá thể...',
        leading: IconButton(
          onPressed: _backToCrabList,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.batches) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm lứa nuôi...',
        onSearchChanged: _batchService.setSearch,
      );
    }

    if (_route == AppRoute.individuals) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm cá thể, thiết bị hoặc khu nuôi...',
        onSearchChanged: _crabService.setSearch,
      );
    }

    if (_route == AppRoute.farmAreas) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm hệ thống...',
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.farmManagement) {
      return _shellTopBar(
        searchHint: 'Tìm mã trại, tên, địa chỉ...',
        onSearchChanged: _farmManagementService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.areaManagement) {
      return _shellTopBar(
        searchHint: 'Tìm mã khu, tên khu...',
        onSearchChanged: _areaManagementService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.areaDetail) {
      return _shellTopBar(
        centerTitle: const SizedBox.shrink(),
        leading: IconButton(
          onPressed: _backToAreaList,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
      );
    }

    if (_route.isProductionRoute) {
      final hint = switch (_route) {
        AppRoute.rowManagement => 'Tìm mã dãy, tên dãy...',
        AppRoute.boxManagement => 'Tìm mã hộp, vị trí...',
        AppRoute.farmingBatchManagement => 'Tìm mã đợt nuôi...',
        AppRoute.productionCrabManagement => 'Tìm mã cua...',
        _ => 'Tìm kiếm...',
      };
      return _shellTopBar(
        searchHint: hint,
        onSearchChanged: _productionManagementService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.cameraAi) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm cá thể, thiết bị hoặc khu nuôi...',
        onSearchChanged: _cameraAiService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.environment) {
      return _shellTopBar(
        searchHint: 'Khu nuôi, thiết bị...',
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.devices) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm thiết bị...',
        onSearchChanged: _iotDeviceService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.alerts) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm cảnh báo...',
        onSearchChanged: _alertService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.farmLogs) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm nhật ký, mã cua...',
        onSearchChanged: _farmLogService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.feed) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm kho, lịch cho ăn...',
        onSearchChanged: _feedService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.harvestSales) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm đơn hàng, mã cua...',
        onSearchChanged: _harvestSalesService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.reports) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm báo cáo, lứa nuôi...',
        onSearchChanged: _farmReportService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.aiInsight) {
      return _shellTopBar(
        searchHint: 'Hỏi Crab Assistant...',
        onSearchChanged: _aiAssistantService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.sensorUpgrade) {
      return _shellTopBar(
        searchHint: 'Tìm kiếm gói cảm biến...',
        centerTitle: const SizedBox.shrink(),
      );
    }

    return _shellTopBar(
      title: 'Dashboard Tổng Quan',
      alertCount: MockDashboardData.alertCount,
      searchHint: 'Tìm kiếm khu vực, ID cua...',
    );
  }

  Widget _buildBody() {
    switch (_route) {
      case AppRoute.dashboard:
        return DashboardContent(displayName: _session.user.displayName);
      case AppRoute.batches:
        return BatchListPage(
          service: _batchService,
          onViewBatch: _openBatchDetail,
        );
      case AppRoute.batchDetail:
        final batch = _selectedBatch ??
            _batchService.getById('CFM-2026-001') ??
            _batchService.batches.first;
        return BatchDetailPage(
          batch: batch,
          service: _batchService,
          onBack: _backToBatchList,
        );
      case AppRoute.farmAreas:
        return const FarmLayoutPage();
      case AppRoute.farmManagement:
        return FarmManagementPage(
          service: _farmManagementService,
          onFarmsChanged: _syncSessionFarmsFromRecords,
        );
      case AppRoute.areaManagement:
        return AreaManagementPage(
          service: _areaManagementService,
          onNavigate: _navigate,
          onOpenDetail: (a) => _openAreaDetail(a.id),
        );
      case AppRoute.areaDetail:
        final areaId = _selectedAreaId ??
            (_areaManagementService.areas.isNotEmpty
                ? _areaManagementService.areas.first.id
                : null);
        if (areaId == null) {
          return AreaManagementPage(
            service: _areaManagementService,
            onNavigate: _navigate,
            onOpenDetail: (a) => _openAreaDetail(a.id),
          );
        }
        return AreaDetailPage(
          service: _areaManagementService,
          areaId: areaId,
          onBack: _backToAreaList,
        );
      case AppRoute.rowManagement:
      case AppRoute.boxManagement:
      case AppRoute.farmingBatchManagement:
      case AppRoute.productionCrabManagement:
        return ProductionEntityPage(
          service: _productionManagementService,
          route: _route,
        );
      case AppRoute.individuals:
        return CrabListPage(
          service: _crabService,
          onViewCrab: _openCrabDetail,
          onOpenHealth: (c) => _openHealthMonitoring(c.id),
        );
      case AppRoute.individualDetail:
        final id = _selectedCrabId ??
            (_crabService.crabs.isNotEmpty
                ? _crabService.crabs.first.id
                : 'CRAB-A01-001');
        return CrabDetailPage(
          crabId: id,
          service: _crabService,
          onBack: _backToCrabList,
          onOpenHealth: () => _openHealthMonitoring(id),
        );
      case AppRoute.individualHealth:
        final id = _selectedCrabId ?? 'CRAB-A01-001';
        return HealthMonitoringPage(
          crabId: id,
          onBack: _backToCrabDetail,
          onOpenHistory: _backToCrabDetail,
        );
      case AppRoute.cameraAi:
        return CameraAiPage(service: _cameraAiService);
      case AppRoute.environment:
        return WaterQualityPage(service: _waterQualityService);
      case AppRoute.devices:
        return IotControlPage(service: _iotDeviceService);
      case AppRoute.alerts:
        return AlertSystemPage(service: _alertService);
      case AppRoute.farmLogs:
        return FarmActivityLogPage(service: _farmLogService);
      case AppRoute.feed:
        return FeedManagementPage(service: _feedService);
      case AppRoute.harvestSales:
        return HarvestSalesPage(service: _harvestSalesService);
      case AppRoute.reports:
        return FarmReportPage(service: _farmReportService);
      case AppRoute.aiInsight:
        return AiInsightPage(service: _aiAssistantService);
      case AppRoute.sensorUpgrade:
        return SensorUpgradePage(service: _sensorKitService);
      case AppRoute.deviceSetup:
        return DeviceSetupPage(
          service: _deviceSetupService,
          connectivity: _connectivityLinkService,
        );
      default:
        return Center(
          child: Text(
            '${_route.label} — đang phát triển',
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
        );
    }
  }
}
