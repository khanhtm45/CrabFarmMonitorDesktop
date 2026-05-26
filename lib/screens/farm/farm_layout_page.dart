import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_farm_layout_data.dart';
import '../../models/box_status.dart';
import '../../models/crab_box.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/farm/box_detail_drawer.dart';
import '../../widgets/farm/crab_box_card.dart';
import '../../widgets/farm/farm_kpi_strip.dart';
import '../../widgets/farm/farm_devices_tab.dart';
import '../../widgets/farm/farm_history_tab.dart';
import '../../widgets/farm/ras_flow_section.dart';
import '../../widgets/shared/ai_assistant_avatar.dart';

class FarmLayoutPage extends StatefulWidget {
  const FarmLayoutPage({super.key});

  @override
  State<FarmLayoutPage> createState() => _FarmLayoutPageState();
}

class _FarmLayoutPageState extends State<FarmLayoutPage>
    with SingleTickerProviderStateMixin {
  late final List<CrabBox> _allBoxes;
  late final TabController _tabController;

  BoxStatus? _statusFilter;
  String? _zoneFilter;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _allBoxes = MockFarmLayoutData.generateBoxes();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<CrabBox> get _filtered {
    return _allBoxes.where((b) {
      if (_zoneFilter != null && b.zone != _zoneFilter) return false;
      if (_statusFilter != null && b.status != _statusFilter) return false;
      if (_search.isNotEmpty &&
          !b.id.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final summary = MockFarmLayoutData.summarize(_allBoxes);
    final filtered = _filtered;
    final mascotMsg = MockFarmLayoutData.mascotMessage(_allBoxes);

    return Column(
      children: [
        _PageTabs(tabController: _tabController),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MapTab(
                summary: summary,
                filtered: filtered,
                statusFilter: _statusFilter,
                zoneFilter: _zoneFilter,
                search: _search,
                mascotMessage: mascotMsg,
                onStatusFilter: (s) => setState(() => _statusFilter = s),
                onZoneFilter: (z) => setState(() => _zoneFilter = z),
                onSearch: (q) => setState(() => _search = q),
                onBoxTap: (box) => showBoxDetailDrawer(context, box),
              ),
              const FarmDevicesTab(),
              const FarmHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageTabs extends StatelessWidget {
  const _PageTabs({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: DashboardColors.cardBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: DashboardColors.cyan,
        labelColor: DashboardColors.cyan,
        unselectedLabelColor: DashboardColors.textMuted,
        labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Bản Đồ'),
          Tab(text: 'Thiết bị'),
          Tab(text: 'Lịch sử'),
        ],
      ),
    );
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab({
    required this.summary,
    required this.filtered,
    required this.statusFilter,
    required this.zoneFilter,
    required this.search,
    required this.mascotMessage,
    required this.onStatusFilter,
    required this.onZoneFilter,
    required this.onSearch,
    required this.onBoxTap,
  });

  final FarmLayoutSummary summary;
  final List<CrabBox> filtered;
  final BoxStatus? statusFilter;
  final String? zoneFilter;
  final String search;
  final String mascotMessage;
  final ValueChanged<BoxStatus?> onStatusFilter;
  final ValueChanged<String?> onZoneFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<CrabBox> onBoxTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Farm Layout / Bản Đồ Trại Nuôi',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Theo dõi sơ đồ tuần hoàn nước và trạng thái từng hộp cua',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              RasFlowSection(components: MockFarmLayoutData.rasFlow),
              const SizedBox(height: 20),
              FarmKpiStrip(summary: summary),
              const SizedBox(height: 20),
              _FilterBar(
                statusFilter: statusFilter,
                zoneFilter: zoneFilter,
                search: search,
                onStatusFilter: onStatusFilter,
                onZoneFilter: onZoneFilter,
                onSearch: onSearch,
              ),
              const SizedBox(height: 20),
              for (final zone in MockFarmLayoutData.zones)
                _ZoneSection(
                  zone: zone,
                  boxes: filtered.where((b) => b.zone == zone).toList(),
                  onBoxTap: onBoxTap,
                ),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Không tìm thấy hộp phù hợp',
                      style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: _MascotBanner(message: mascotMessage),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.statusFilter,
    required this.zoneFilter,
    required this.search,
    required this.onStatusFilter,
    required this.onZoneFilter,
    required this.onSearch,
  });

  final BoxStatus? statusFilter;
  final String? zoneFilter;
  final String search;
  final ValueChanged<BoxStatus?> onStatusFilter;
  final ValueChanged<String?> onZoneFilter;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _zoneChip('Tất cả', zoneFilter == null, () => onZoneFilter(null)),
              for (final z in MockFarmLayoutData.zones)
                _zoneChip('Khu $z', zoneFilter == z, () => onZoneFilter(z)),
              const SizedBox(width: 8),
              _statusChip('Tất cả', statusFilter == null, () => onStatusFilter(null)),
              for (final s in BoxStatus.values)
                _statusChip(s.label, statusFilter == s, () => onStatusFilter(s)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 280,
            height: 40,
            child: TextField(
              onChanged: onSearch,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Tìm hộp (e.g. A01)...',
                hintStyle: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: DashboardColors.darkNavy,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoneChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: DashboardColors.purple.withValues(alpha: 0.25),
      checkmarkColor: DashboardColors.cyan,
      labelStyle: GoogleFonts.notoSans(
        fontSize: 11,
        color: selected ? DashboardColors.cyan : DashboardColors.textMuted,
      ),
      side: BorderSide(
        color: selected ? DashboardColors.cyan : DashboardColors.cardBorder,
      ),
    );
  }

  Widget _statusChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: DashboardColors.blue.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.notoSans(
        fontSize: 11,
        color: selected ? DashboardColors.textPrimary : DashboardColors.textMuted,
      ),
      side: BorderSide(
        color: selected ? DashboardColors.blue : DashboardColors.cardBorder,
      ),
    );
  }
}

class _ZoneSection extends StatelessWidget {
  const _ZoneSection({
    required this.zone,
    required this.boxes,
    required this.onBoxTap,
  });

  final String zone;
  final List<CrabBox> boxes;
  final ValueChanged<CrabBox> onBoxTap;

  @override
  Widget build(BuildContext context) {
    if (boxes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khu $zone — ${boxes.length} / ${MockFarmLayoutData.boxesPerZone} hộp',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const cols = MockFarmLayoutData.columnsPerRow;
              const spacing = 10.0;
              const itemHeight = 80.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: boxes.map((box) {
                  return SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: CrabBoxCard(
                      box: box,
                      highlighted: box.id == 'A07',
                      onTap: () => onBoxTap(box),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MascotBanner extends StatelessWidget {
  const _MascotBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardColors.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.purple.withValues(alpha: 0.4)),
        boxShadow: [DashboardColors.glowShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiAssistantAvatar(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crab Assistant',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
