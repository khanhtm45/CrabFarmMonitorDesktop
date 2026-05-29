enum AppRoute {
  dashboard,
  batches,
  batchDetail,
  farmAreas,
  farmManagement,
  productionManagement,
  individuals,
  individualDetail,
  individualHealth,
  feed,
  cameraAi,
  devices,
  environment,
  alerts,
  farmLogs,
  harvestSales,
  reports,
  aiInsight,
  sensorUpgrade,
  deviceSetup,
}

extension AppRouteX on AppRoute {
  String get label => switch (this) {
        AppRoute.dashboard => 'Dashboard',
        AppRoute.batches => 'Lứa nuôi',
        AppRoute.batchDetail => 'Chi tiết lứa',
        AppRoute.farmAreas => 'Bản đồ trại',
        AppRoute.farmManagement => 'Quản lý trại',
        AppRoute.productionManagement => 'Quản lý sản xuất',
        AppRoute.individuals => 'Cá thể cua',
        AppRoute.individualDetail => 'Chi tiết cá thể',
        AppRoute.individualHealth => 'Health Monitoring',
        AppRoute.feed => 'Thức ăn',
        AppRoute.cameraAi => 'Camera AI',
        AppRoute.devices => 'Điều khiển thiết bị',
        AppRoute.environment => 'Cảm biến môi trường',
        AppRoute.alerts => 'Hệ thống cảnh báo',
        AppRoute.farmLogs => 'Nhật ký',
        AppRoute.harvestSales => 'Thu hoạch & Bán hàng',
        AppRoute.reports => 'Báo cáo',
        AppRoute.aiInsight => 'AI Insight',
        AppRoute.sensorUpgrade => 'Nâng cấp Sensor',
        AppRoute.deviceSetup => 'Device Setup',
      };

  bool get isImplemented =>
      this == AppRoute.dashboard ||
      this == AppRoute.batches ||
      this == AppRoute.batchDetail ||
      this == AppRoute.farmAreas ||
      this == AppRoute.farmManagement ||
      this == AppRoute.productionManagement ||
      this == AppRoute.individuals ||
      this == AppRoute.individualDetail ||
      this == AppRoute.individualHealth ||
      this == AppRoute.cameraAi ||
      this == AppRoute.environment ||
      this == AppRoute.devices ||
      this == AppRoute.alerts ||
      this == AppRoute.farmLogs ||
      this == AppRoute.feed ||
      this == AppRoute.harvestSales ||
      this == AppRoute.reports ||
      this == AppRoute.aiInsight ||
      this == AppRoute.sensorUpgrade ||
      this == AppRoute.deviceSetup;
}
