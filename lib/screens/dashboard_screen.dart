import 'package:flutter/material.dart';

import '../data/mock_dashboard_data.dart';
import '../widgets/dashboard/charts_section.dart';
import '../widgets/dashboard/kpi_widgets.dart';
import '../widgets/dashboard/right_panel.dart';

/// Dashboard body used inside [MainShellScreen].
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key, required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _MainScrollArea(userName: displayName)),
        SizedBox(
          width: 320,
          child: _RightColumn(healthScore: MockDashboardData.healthScore),
        ),
      ],
    );
  }
}

class _MainScrollArea extends StatelessWidget {
  const _MainScrollArea({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WelcomeSection(userName: userName),
          const SizedBox(height: 24),
          const Text(
            'Tổng quan',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const KpiGrid(items: MockDashboardData.summaryKpis, columns: 4),
          const SizedBox(height: 24),
          const Text(
            'Chi tiết KPI',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const KpiGrid(items: MockDashboardData.kpiRow1, columns: 6),
          const SizedBox(height: 12),
          const KpiGrid(items: MockDashboardData.kpiRow2, columns: 6),
          const SizedBox(height: 24),
          const StatusDistributionCard(),
          const SizedBox(height: 24),
          const ChartsSection(),
          const SizedBox(height: 24),
          const AlertsPanel(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({required this.healthScore});

  final int healthScore;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      child: Column(
        children: [
          const EnvironmentPanel(),
          const SizedBox(height: 16),
          const DeviceAlertSummary(),
          const SizedBox(height: 16),
          CrabAssistantCard(healthScore: healthScore),
        ],
      ),
    );
  }
}
