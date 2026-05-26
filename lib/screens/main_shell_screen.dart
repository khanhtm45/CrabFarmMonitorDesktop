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
import '../services/farm_log_service.dart';
import '../services/feed_service.dart';
import '../services/harvest_sales_service.dart';
import '../services/farm_report_service.dart';
import '../services/ai_assistant_service.dart';
import '../services/sensor_kit_service.dart';
import '../services/device_setup_service.dart';
import '../models/auth_models.dart';
import '../services/connectivity_link_service.dart';
import '../services/theme_mode_service.dart';
import 'login_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.session,
  });

  final AuthSession session;

  String get displayName => session.user.displayName;
  String get email => session.user.email;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  final _batchService = BatchService();
  final _crabService = CrabService();
  final _cameraAiService = CameraAiService();
  late final WaterQualityService _waterQualityService;
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

  @override
  void initState() {
    super.initState();
    _connectivityLinkService =
        ConnectivityLinkService(session: widget.session);
    _waterQualityService = WaterQualityService(session: widget.session);
    _connectivityLinkService.addListener(_onConnectivityUpdate);
    _connectivityLinkService.refreshCloud();
  }

  @override
  void dispose() {
    _connectivityLinkService.removeListener(_onConnectivityUpdate);
    super.dispose();
  }

  void _onConnectivityUpdate() => setState(() {});

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
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        title: 'Device Setup',
        searchHint: 'Tìm node ESP32...',
        centerTitle: const SizedBox.shrink(),
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        leading: IconButton(
          onPressed: () => _navigate(AppRoute.dashboard),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
      );
    }

    if (_route == AppRoute.batchDetail && _selectedBatch != null) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm lứa nuôi, thiết bị...',
        leading: IconButton(
          onPressed: _backToBatchList,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.individualHealth && _selectedCrabId != null) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm cá thể, thiết bị hoặc khu nuôi...',
        leading: IconButton(
          onPressed: _backToCrabDetail,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.individualDetail && _selectedCrabId != null) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm cá thể...',
        leading: IconButton(
          onPressed: _backToCrabList,
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
        ),
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.batches) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm lứa nuôi...',
        onSearchChanged: _batchService.setSearch,
      );
    }

    if (_route == AppRoute.individuals) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm cá thể, thiết bị hoặc khu nuôi...',
        onSearchChanged: _crabService.setSearch,
      );
    }

    if (_route == AppRoute.farmAreas) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm hệ thống...',
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.cameraAi) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm cá thể, thiết bị hoặc khu nuôi...',
        onSearchChanged: _cameraAiService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.environment) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Khu nuôi, thiết bị...',
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.devices) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm thiết bị...',
        onSearchChanged: _iotDeviceService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.alerts) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm cảnh báo...',
        onSearchChanged: _alertService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.farmLogs) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm nhật ký, mã cua...',
        onSearchChanged: _farmLogService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.feed) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm kho, lịch cho ăn...',
        onSearchChanged: _feedService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.harvestSales) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm đơn hàng, mã cua...',
        onSearchChanged: _harvestSalesService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.reports) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm báo cáo, lứa nuôi...',
        onSearchChanged: _farmReportService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.aiInsight) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Hỏi Crab Assistant...',
        onSearchChanged: _aiAssistantService.setSearch,
        centerTitle: const SizedBox.shrink(),
      );
    }

    if (_route == AppRoute.sensorUpgrade) {
      return AppTopBar(
        displayName: widget.session.user.displayName,
        onLogout: _logout,
        connectivity: _connectivityLinkService,
        onOpenDeviceSetup: _openDeviceSetupCloudEdge,
        onSettingsTap: _openDeviceSetup,
        searchHint: 'Tìm kiếm gói cảm biến...',
        centerTitle: const SizedBox.shrink(),
      );
    }

    return AppTopBar(
      title: 'Dashboard Tổng Quan',
      displayName: widget.displayName,
      alertCount: MockDashboardData.alertCount,
      searchHint: 'Tìm kiếm khu vực, ID cua...',
      connectivity: _connectivityLinkService,
      onOpenDeviceSetup: _openDeviceSetupCloudEdge,
      onSettingsTap: _openDeviceSetup,
      onLogout: _logout,
    );
  }

  Widget _buildBody() {
    switch (_route) {
      case AppRoute.dashboard:
        return DashboardContent(displayName: widget.session.user.displayName);
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
