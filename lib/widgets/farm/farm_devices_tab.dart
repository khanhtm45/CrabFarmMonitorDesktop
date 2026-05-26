import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_farm_devices_data.dart';
import '../../models/device_status.dart';
import '../../models/farm_device.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';
import '../shared/accent_strip_container.dart';
import 'farm_device_dialogs.dart';

class FarmDevicesTab extends StatefulWidget {
  const FarmDevicesTab({super.key});

  @override
  State<FarmDevicesTab> createState() => _FarmDevicesTabState();
}

class _FarmDevicesTabState extends State<FarmDevicesTab> {
  final List<FarmDevice> _devices = List.of(MockFarmDevicesData.allDevices());
  int _page = 1;
  DeviceFilterResult _filter = const DeviceFilterResult();

  List<FarmDevice> get _filtered {
    return _devices.where((d) {
      if (_filter.status != null && d.status != _filter.status) return false;
      if (_filter.search.isNotEmpty) {
        final q = _filter.search.toLowerCase();
        final haystack =
            '${d.id} ${d.name} ${d.typeLabel} ${d.location}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  List<FarmDevice> get _pageItems {
    final list = _filtered;
    final start = (_page - 1) * MockFarmDevicesData.pageSize;
    if (start >= list.length) return [];
    final end = (start + MockFarmDevicesData.pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int get _totalPages =>
      (_filtered.length / MockFarmDevicesData.pageSize).ceil().clamp(1, 99);

  Future<void> _openAddDevice() async {
    final device = await showAddDeviceDialog(
      context,
      suggestedId: generateDeviceId(_devices),
    );
    if (device == null || !mounted) return;
    setState(() {
      _devices.insert(0, device);
      _page = 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm thiết bị ${device.id}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openFilter() async {
    final result = await showDeviceFilterSheet(context, current: _filter);
    if (result == null || !mounted) return;
    setState(() {
      _filter = result;
      _page = 1;
    });
  }

  Future<void> _exportCsv() async {
    await showExportDevicesDialog(context, _filtered);
  }

  Future<void> _openSettings(FarmDevice device) async {
    final updated = await showDeviceSettingsDialog(context, device);
    if (updated == null || !mounted) return;
    final i = _devices.indexWhere((d) => d.id == updated.id);
    if (i < 0) return;
    setState(() => _devices[i] = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật ${updated.id}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _syncDevice(FarmDevice device) {
    final i = _devices.indexWhere((d) => d.id == device.id);
    if (i < 0) return;
    setState(() {
      _devices[i] = FarmDevice(
        id: device.id,
        name: device.name,
        typeLabel: device.typeLabel,
        location: device.location,
        status: device.status,
        lastSync: 'Just now',
        icon: device.icon,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã đồng bộ ${device.id}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = DeviceAreaSummary.fromDevices(_devices);
    final filtered = _filtered;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Breadcrumb(),
              const SizedBox(height: 8),
              Text(
                'Quản lý Thiết bị Khu vực',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${MockFarmDevicesData.areaName} — giám sát phần cứng IoT và đồng bộ dữ liệu',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _DeviceKpiRow(summary: summary),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Danh sách Thiết bị Chi tiết',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: _openFilter,
                          icon: Icon(
                            Icons.filter_list,
                            size: 16,
                            color: _filter.hasActiveFilter
                                ? DashboardColors.cyan
                                : null,
                          ),
                          label: Text(
                            _filter.hasActiveFilter ? 'Bộ lọc (*)' : 'Bộ lọc',
                          ),
                          style: _outlineStyle,
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _exportCsv,
                          icon: const Icon(Icons.download_outlined, size: 16),
                          label: const Text('Xuất CSV'),
                          style: _outlineStyle,
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _openAddDevice,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm thiết bị'),
                          style: FilledButton.styleFrom(
                            backgroundColor: DashboardColors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'Không có thiết bị phù hợp bộ lọc',
                            style: GoogleFonts.notoSans(
                              color: DashboardColors.textMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      _DeviceTable(
                        devices: _pageItems,
                        onSync: _syncDevice,
                        onSettings: _openSettings,
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Displaying ${_pageItems.length} of ${filtered.length} devices'
                          '${_filter.hasActiveFilter ? ' (đã lọc)' : ''}',
                          style: GoogleFonts.notoSans(
                            color: DashboardColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        _Pagination(
                          current: _page,
                          total: _totalPages,
                          onPage: (p) => setState(() => _page = p),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        Positioned(
          right: 32,
          bottom: 32,
          child: FloatingActionButton(
            onPressed: _openAddDevice,
            backgroundColor: DashboardColors.purple,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  static final _outlineStyle = OutlinedButton.styleFrom(
    foregroundColor: DashboardColors.textMuted,
    side: BorderSide(color: DashboardColors.cardBorder),
  );
}

class _Breadcrumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          MockFarmDevicesData.areaName,
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 13),
        ),
        Text('  >  ', style: GoogleFonts.notoSans(color: DashboardColors.textMuted)),
        Text(
          'Chi tiết quản lý',
          style: GoogleFonts.notoSans(color: DashboardColors.cyan, fontSize: 13),
        ),
      ],
    );
  }
}

class _DeviceKpiRow extends StatelessWidget {
  const _DeviceKpiRow({required this.summary});

  final DeviceAreaSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1200 ? 4 : c.maxWidth > 700 ? 2 : 1;
        final spacing = 12.0;
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: w,
              child: _KpiCard(
                label: 'Tổng thiết bị',
                value: '${summary.total}',
                subtext: '+3 tháng này',
                subColor: DashboardColors.healthy,
                accent: DashboardColors.purple,
              ),
            ),
            SizedBox(
              width: w,
              child: _KpiCard(
                label: 'Đang hoạt động',
                value: '${summary.active}',
                subtext: '${summary.activePercent}%',
                progress: summary.activePercent / 100,
                progressColor: DashboardColors.cyan,
                accent: DashboardColors.cyan,
              ),
            ),
            SizedBox(
              width: w,
              child: _KpiCard(
                label: 'Cần bảo trì',
                value: '${summary.maintenance}',
                subtext: 'Khẩn cấp: ${summary.emergencyMaintenance}',
                subColor: DashboardColors.molting,
                accent: DashboardColors.molting,
                leftBorder: true,
              ),
            ),
            SizedBox(
              width: w,
              child: _KpiCard(
                label: 'Hiệu suất kết nối',
                value: '${summary.connectionPercent}%',
                subtext: '${summary.offline} offline',
                progress: summary.connectionPercent / 100,
                progressColor: DashboardColors.blue,
                accent: DashboardColors.blue,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.accent,
    this.subColor,
    this.progress,
    this.progressColor,
    this.leftBorder = false,
  });

  final String label;
  final String value;
  final String subtext;
  final Color accent;
  final Color? subColor;
  final double? progress;
  final Color? progressColor;
  final bool leftBorder;

  @override
  Widget build(BuildContext context) {
    return AccentStripContainer(
      accentColor: leftBorder ? accent : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSans(
              color: subColor ?? DashboardColors.textMuted,
              fontSize: 11,
              height: 1.2,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: DashboardColors.cardBorder,
                valueColor: AlwaysStoppedAnimation(progressColor ?? accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeviceTable extends StatelessWidget {
  const _DeviceTable({
    required this.devices,
    required this.onSync,
    required this.onSettings,
  });

  final List<FarmDevice> devices;
  final ValueChanged<FarmDevice> onSync;
  final ValueChanged<FarmDevice> onSettings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 44,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 88,
        columnSpacing: 28,
        headingTextStyle: GoogleFonts.notoSans(
          color: DashboardColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
        columns: const [
          DataColumn(label: Text('DEVICE ID')),
          DataColumn(label: Text('LOẠI THIẾT BỊ')),
          DataColumn(label: Text('VỊ TRÍ (BỂ)')),
          DataColumn(label: Text('TRẠNG THÁI')),
          DataColumn(label: Text('LẦN CUỐI ĐỒNG BỘ')),
          DataColumn(label: Text('THAO TÁC')),
        ],
        rows: devices.map((d) => _row(context, d)).toList(),
      ),
    );
  }

  Widget _tableIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: DashboardColors.textMuted),
      ),
    );
  }

  DataRow _row(BuildContext context, FarmDevice d) {
    return DataRow(
      cells: [
        DataCell(Text(d.id, style: GoogleFonts.notoSans(color: DashboardColors.cyan))),
        DataCell(
          Row(
            children: [
              Icon(d.icon, size: 16, color: DashboardColors.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      d.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      d.typeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 9,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(d.location)),
        DataCell(_StatusDot(status: d.status)),
        DataCell(Text(d.lastSync)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tableIcon(Icons.refresh, () => onSync(d)),
              _tableIcon(Icons.settings_outlined, () => onSettings(d)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status.label,
          style: GoogleFonts.notoSans(color: status.color, fontSize: 12),
        ),
      ],
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.current,
    required this.total,
    required this.onPage,
  });

  final int current;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.chevron_left, current > 1 ? () => onPage(current - 1) : null),
        for (var i = 1; i <= total; i++) ...[
          const SizedBox(width: 4),
          _num(i, i == current),
        ],
        const SizedBox(width: 4),
        _btn(Icons.chevron_right, current < total ? () => onPage(current + 1) : null),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) => IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: DashboardColors.textMuted),
        style: IconButton.styleFrom(backgroundColor: DashboardColors.card),
      );

  Widget _num(int page, bool active) => Material(
        color: active ? DashboardColors.purple : DashboardColors.card,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: active ? null : () => onPage(page),
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: Text(
                '$page',
                style: GoogleFonts.notoSans(
                  color: active ? Colors.white : DashboardColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
}
