import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/area_status.dart';
import '../../models/production_models.dart';
import '../../navigation/app_route.dart';
import '../../services/area_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/area/area_form_dialog.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/production/production_dialogs.dart' show confirmDelete;

class AreaManagementPage extends StatefulWidget {
  const AreaManagementPage({
    super.key,
    required this.service,
    this.onNavigate,
    this.onOpenDetail,
  });

  final AreaManagementService service;
  final void Function(AppRoute route)? onNavigate;
  final void Function(AreaRecord area)? onOpenDetail;

  @override
  State<AreaManagementPage> createState() => _AreaManagementPageState();
}

class _AreaManagementPageState extends State<AreaManagementPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    _searchCtrl.text = widget.service.search;
    if (!widget.service.loading && widget.service.areas.isEmpty) {
      widget.service.load();
    }
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final items = svc.pagedAreas;
    final filtered = svc.filteredAreas;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Breadcrumb(
            onDashboard: () => widget.onNavigate?.call(AppRoute.dashboard),
            onFarm: () => widget.onNavigate?.call(AppRoute.farmManagement),
          ),
          const SizedBox(height: 12),
          Text(
            'Quản lý Khu',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1100
                  ? 4
                  : c.maxWidth > 700
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: cols == 1 ? 2.8 : 2.2,
                children: [
                  _StatCard(
                    title: 'TỔNG SỐ KHU',
                    value: '${svc.summary.total}',
                    subtitle: '${svc.areas.length} khu trên trại',
                    accent: DashboardColors.purple,
                    icon: Icons.grid_view_rounded,
                  ),
                  _StatCard(
                    title: 'ĐANG HOẠT ĐỘNG',
                    value: '${svc.summary.active}',
                    subtitle: svc.summary.total > 0
                        ? 'Hiệu suất: ${((svc.summary.active / svc.summary.total) * 100).round()}%'
                        : '—',
                    accent: DashboardColors.seaGreen,
                    icon: Icons.bolt_rounded,
                  ),
                  _StatCard(
                    title: 'KHU BẢO TRÌ',
                    value: '${svc.summary.maintenance}',
                    subtitle: 'Theo dõi bảo trì định kỳ',
                    accent: DashboardColors.oceanBlue,
                    icon: Icons.build_circle_outlined,
                  ),
                  _StatCard(
                    title: 'TỔNG SỐ HỘP NUÔI',
                    value: '${svc.summary.totalBoxes}',
                    subtitle: svc.summary.total > 0
                        ? 'TB ${(svc.summary.totalBoxes / svc.summary.total).round()} hộp/khu'
                        : '—',
                    accent: const Color(0xFFE879F9),
                    icon: Icons.inventory_2_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          if (svc.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                svc.error!,
                style: GoogleFonts.notoSans(color: DashboardColors.risk),
              ),
            ),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final f in AreaStatusFilter.values)
                      FilterChip(
                        label: Text(f.label),
                        selected: svc.statusFilter == f,
                        onSelected: svc.loading
                            ? null
                            : (_) => svc.setStatusFilter(f),
                        selectedColor:
                            DashboardColors.seaGreen.withValues(alpha: 0.25),
                        checkmarkColor: DashboardColors.seaGreen,
                        labelStyle: GoogleFonts.notoSans(
                          color: svc.statusFilter == f
                              ? DashboardColors.seaGreen
                              : DashboardColors.textMuted,
                          fontWeight: svc.statusFilter == f
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: svc.statusFilter == f
                              ? DashboardColors.seaGreen
                              : DashboardColors.cardBorder,
                        ),
                      ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: svc.setSearch,
                        decoration: InputDecoration(
                          hintText: 'Tìm theo mã, tên...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: DashboardColors.textMuted,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: DashboardColors.darkNavy,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: DashboardColors.cardBorder,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.notoSans(
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: svc.loading
                          ? null
                          : () => showAreaFormDialog(context, svc),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Thêm Khu'),
                      style: FilledButton.styleFrom(
                        backgroundColor: DashboardColors.seaGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tải lại',
                      onPressed: svc.loading ? null : svc.load,
                      icon: Icon(Icons.refresh, color: DashboardColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (svc.loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Chưa có khu phù hợp bộ lọc.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        DashboardColors.darkNavy.withValues(alpha: 0.6),
                      ),
                      dataRowMinHeight: 56,
                      columns: [
                        for (final h in [
                          'Mã khu',
                          'Tên khu',
                          'Số dãy',
                          'Số hộp',
                          'Trạng thái',
                          'Ngày tạo',
                          'Thao tác',
                        ])
                          DataColumn(
                            label: Text(
                              h,
                              style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.w600,
                                color: DashboardColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                      rows: items.map((a) {
                        return DataRow(
                          cells: [
                            DataCell(Text(
                              a.areaCode,
                              style: GoogleFonts.notoSans(
                                color: DashboardColors.cyan,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    a.areaName,
                                    style: GoogleFonts.notoSans(
                                      color: DashboardColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (a.description?.isNotEmpty == true)
                                    Text(
                                      a.description!,
                                      style: GoogleFonts.notoSans(
                                        color: DashboardColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(Text('${a.rowCount}')),
                            DataCell(Text('${a.boxCount}')),
                            DataCell(_StatusBadge(status: a.status)),
                            DataCell(Text(
                              a.createdAt != null
                                  ? _formatDate(a.createdAt!)
                                  : '—',
                            )),
                            DataCell(_RowActions(
                              onView: () => widget.onOpenDetail?.call(a),
                              onEdit: () =>
                                  showAreaFormDialog(context, svc, existing: a),
                              onDelete: () async {
                                if (!await confirmDelete(
                                  context,
                                  title: 'Xóa khu?',
                                  message:
                                      '${a.areaName} (${a.areaCode})?',
                                )) {
                                  return;
                                }
                                try {
                                  await svc.deleteArea(a);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã xóa')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                }
                              },
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      filtered.isEmpty
                          ? 'Không có dữ liệu'
                          : 'Hiển thị ${svc.page * AreaManagementService.pageSize + 1} - '
                              '${(svc.page * AreaManagementService.pageSize + items.length).clamp(0, filtered.length)} '
                              'trong ${filtered.length} khu',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: svc.page > 0
                          ? () => svc.setPage(svc.page - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    ...List.generate(svc.totalPages.clamp(1, 5), (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: TextButton(
                          onPressed: () => svc.setPage(i),
                          style: TextButton.styleFrom(
                            backgroundColor: svc.page == i
                                ? DashboardColors.seaGreen
                                    .withValues(alpha: 0.2)
                                : null,
                          ),
                          child: Text('${i + 1}'),
                        ),
                      );
                    }),
                    IconButton(
                      onPressed: svc.page < svc.totalPages - 1
                          ? () => svc.setPage(svc.page + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({this.onDashboard, this.onFarm});

  final VoidCallback? onDashboard;
  final VoidCallback? onFarm;

  @override
  Widget build(BuildContext context) {
    TextStyle link = GoogleFonts.notoSans(
      color: DashboardColors.oceanBlue,
      fontSize: 13,
    );
    TextStyle current = GoogleFonts.notoSans(
      color: DashboardColors.textMuted,
      fontSize: 13,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          onTap: onDashboard,
          child: Text('Dashboard', style: link),
        ),
        Text('  >  ', style: current),
        InkWell(
          onTap: onFarm,
          child: Text('Quản lý Trại', style: link),
        ),
        Text('  >  ', style: current),
        Text('Quản lý Khu', style: current.copyWith(color: DashboardColors.textPrimary)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: accent.withValues(alpha: 0.35),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: accent.withValues(alpha: 0.85), size: 32),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = AreaStatusUi.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: c),
          const SizedBox(width: 6),
          Text(
            AreaStatusUi.label(status),
            style: GoogleFonts.notoSans(color: c, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Xem chi tiết',
          onPressed: onView,
          icon: const Icon(Icons.visibility_outlined, size: 20),
        ),
        IconButton(
          tooltip: 'Chỉnh sửa',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 20),
        ),
        IconButton(
          tooltip: 'Xóa',
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline,
            size: 20,
            color: DashboardColors.risk.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
