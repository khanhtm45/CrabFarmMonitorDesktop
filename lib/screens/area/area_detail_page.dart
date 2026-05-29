import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/area_status.dart';
import '../../models/production_models.dart';
import '../../services/area_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/area/area_form_dialog.dart';
import '../../widgets/dashboard/glass_card.dart';

class AreaDetailPage extends StatefulWidget {
  const AreaDetailPage({
    super.key,
    required this.service,
    required this.areaId,
    required this.onBack,
  });

  final AreaManagementService service;
  final String areaId;
  final VoidCallback onBack;

  @override
  State<AreaDetailPage> createState() => _AreaDetailPageState();
}

class _AreaDetailPageState extends State<AreaDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  AreaRecord? _detail;
  List<RowRecord> _rows = [];
  List<BoxRecord> _boxes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.service.loadAreaDetail(widget.areaId);
      setState(() {
        _detail = r.detail;
        _rows = r.rows;
        _boxes = r.boxes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                color: DashboardColors.textMuted,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiết khu',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      d?.areaName ?? '…',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (d != null)
                FilledButton.icon(
                  onPressed: () => showAreaFormDialog(
                    context,
                    widget.service,
                    existing: d,
                  ).then((_) => _load()),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Sửa khu'),
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardColors.oceanBlue,
                  ),
                ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        if (_loading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Expanded(
            child: Center(
              child: Text(
                _error!,
                style: GoogleFonts.notoSans(color: DashboardColors.risk),
              ),
            ),
          )
        else if (d == null)
          const Expanded(child: Center(child: Text('Không tìm thấy khu')))
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth > 900;
                      return Flex(
                        direction: wide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: wide ? 2 : 0,
                            child: GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _InfoRow('Mã khu', d.areaCode),
                                  _InfoRow('Tên khu', d.areaName),
                                  _InfoRow(
                                    'Mô tả',
                                    d.description?.isNotEmpty == true
                                        ? d.description!
                                        : '—',
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Trạng thái: ',
                                        style: GoogleFonts.notoSans(
                                          color: DashboardColors.textMuted,
                                        ),
                                      ),
                                      _StatusChip(status: d.status),
                                    ],
                                  ),
                                  if (d.createdAt != null)
                                    _InfoRow(
                                      'Ngày tạo',
                                      _formatDate(d.createdAt!),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                          Expanded(
                            flex: wide ? 3 : 0,
                            child: GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: wide ? 4 : 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.4,
                              children: [
                                _MiniStat(
                                  label: 'Số dãy',
                                  value: '${d.rowCount}',
                                  icon: Icons.view_week_outlined,
                                  color: DashboardColors.purple,
                                ),
                                _MiniStat(
                                  label: 'Số hộp',
                                  value: '${d.boxCount}',
                                  icon: Icons.inventory_2_outlined,
                                  color: DashboardColors.cyan,
                                ),
                                _MiniStat(
                                  label: 'ESP32',
                                  value: '${d.esp32Count}',
                                  icon: Icons.sensors,
                                  color: DashboardColors.seaGreen,
                                ),
                                _MiniStat(
                                  label: 'Camera',
                                  value: '${d.cameraCount}',
                                  icon: Icons.videocam_outlined,
                                  color: DashboardColors.oceanBlue,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    labelColor: DashboardColors.seaGreen,
                    unselectedLabelColor: DashboardColors.textMuted,
                    indicatorColor: DashboardColors.seaGreen,
                    tabs: const [
                      Tab(text: 'Danh sách dãy'),
                      Tab(text: 'Danh sách hộp'),
                      Tab(text: 'Thiết bị IoT'),
                      Tab(text: 'Camera AI'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 360,
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _SimpleTable(
                          columns: const ['Mã dãy', 'Tên dãy'],
                          rows: _rows
                              .map((r) => [r.rowCode, r.rowName])
                              .toList(),
                          empty: 'Chưa có dãy.',
                        ),
                        _SimpleTable(
                          columns: const ['Mã hộp', 'Vị trí', 'TT'],
                          rows: _boxes
                              .map((b) => [
                                    b.boxCode,
                                    b.position ?? '—',
                                    b.status,
                                  ])
                              .toList(),
                          empty: 'Chưa có hộp.',
                        ),
                        _DevicePlaceholder(
                          count: d.esp32Count,
                          label: 'ESP32 / node trong khu',
                        ),
                        _DevicePlaceholder(
                          count: d.cameraCount,
                          label: 'Camera gắn hộp trong khu',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = AreaStatusUi.color(status);
    return Chip(
      label: Text(AreaStatusUi.label(status)),
      backgroundColor: c.withValues(alpha: 0.15),
      side: BorderSide(color: c.withValues(alpha: 0.4)),
      labelStyle: GoogleFonts.notoSans(color: c, fontSize: 12),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTable extends StatelessWidget {
  const _SimpleTable({
    required this.columns,
    required this.rows,
    required this.empty,
  });

  final List<String> columns;
  final List<List<String>> rows;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Text(
          empty,
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
      );
    }
    return GlassCard(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            for (final c in columns)
              DataColumn(
                label: Text(
                  c,
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textMuted,
                  ),
                ),
              ),
          ],
          rows: rows
              .map(
                (cells) => DataRow(
                  cells: [
                    for (final cell in cells) DataCell(Text(cell)),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DevicePlaceholder extends StatelessWidget {
  const _DevicePlaceholder({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: GoogleFonts.notoSans(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: DashboardColors.seaGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              'Chi tiết thiết bị: mở menu Điều khiển thiết bị / Camera AI',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                color: DashboardColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
