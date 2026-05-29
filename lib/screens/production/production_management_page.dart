import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../services/production_management_service.dart';
import '../../theme/dashboard_theme.dart';
import '../../widgets/dashboard/glass_card.dart';
import '../../widgets/production/production_dialogs.dart';

class ProductionManagementPage extends StatefulWidget {
  const ProductionManagementPage({super.key, required this.service});

  final ProductionManagementService service;

  @override
  State<ProductionManagementPage> createState() =>
      _ProductionManagementPageState();
}

class _ProductionManagementPageState extends State<ProductionManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _tabs.addListener(_onTabChanged);
    widget.service.addListener(_onUpdate);
    widget.service.loadAreas();
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging) {
      widget.service.setTab(ProductionTab.values[_tabs.index]);
      widget.service.loadCurrentTab();
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final farm = svc.session.selectedFarm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quản lý sản xuất',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Trại: ${farm.name} (${farm.code}) — Mã tự động K-, D-, H-, BT-, C- theo từng cấp',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 14,
                ),
              ),
              if (svc.error != null) ...[
                const SizedBox(height: 12),
                Text(svc.error!, style: GoogleFonts.notoSans(color: DashboardColors.risk)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: DashboardColors.cyan,
          unselectedLabelColor: DashboardColors.textMuted,
          indicatorColor: DashboardColors.cyan,
          tabs: const [
            Tab(text: 'Khu'),
            Tab(text: 'Dãy'),
            Tab(text: 'Hộp nuôi'),
            Tab(text: 'Đợt nuôi'),
            Tab(text: 'Cua'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _AreaTab(svc: svc),
              _RowTab(svc: svc),
              _BoxTab(svc: svc),
              _BatchTab(svc: svc),
              _CrabTab(svc: svc),
            ],
          ),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.svc,
    required this.canAdd,
    required this.onAdd,
    required this.addLabel,
  });

  final ProductionManagementService svc;
  final bool canAdd;
  final VoidCallback? onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canAdd)
          FilledButton.icon(
            onPressed: svc.loading ? null : onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(addLabel),
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
          ),
        const Spacer(),
        IconButton(
          onPressed: svc.loading ? null : () => svc.loadCurrentTab(),
          tooltip: 'Tải lại',
          icon: Icon(Icons.refresh, color: DashboardColors.textMuted),
        ),
      ],
    );
  }
}

class _ParentDropdown<T> extends StatelessWidget {
  const _ParentDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
          filled: true,
          fillColor: DashboardColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: DashboardColors.cardBorder),
          ),
        ),
        dropdownColor: DashboardColors.card,
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
        items: [
          const DropdownMenuItem(value: null, child: Text('— Chọn —')),
          ...items.map((e) {
            final id = (e as dynamic).id as String;
            return DropdownMenuItem(value: id, child: Text(itemLabel(e)));
          }),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _AreaTab extends StatelessWidget {
  const _AreaTab({required this.svc});
  final ProductionManagementService svc;

  @override
  Widget build(BuildContext context) {
    final items = svc.filteredAreasWithSearch;
    return _TabScaffold(
      svc: svc,
      toolbar: _Toolbar(
        svc: svc,
        canAdd: true,
        addLabel: 'Thêm khu',
        onAdd: () => showAreaFormDialog(context, svc),
      ),
      child: _DataTableWrapper(
        loading: svc.loading,
        empty: items.isEmpty,
        table: DataTable(
          columns: const [
            DataColumn(label: Text('Mã')),
            DataColumn(label: Text('Tên khu')),
            DataColumn(label: Text('Mô tả')),
            DataColumn(label: Text('')),
          ],
          rows: items.map((a) {
            return DataRow(cells: [
              DataCell(Text(a.areaCode)),
              DataCell(Text(a.areaName)),
              DataCell(Text(a.description ?? '—')),
              DataCell(_rowActions(
                onEdit: () => showAreaFormDialog(context, svc, existing: a),
                onDelete: () async {
                  if (!await confirmDelete(context,
                      title: 'Xóa khu?',
                      message: '${a.areaName} (${a.areaCode})?')) return;
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
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _RowTab extends StatelessWidget {
  const _RowTab({required this.svc});
  final ProductionManagementService svc;

  @override
  Widget build(BuildContext context) {
    final items = svc.filteredRows;
    return _TabScaffold(
      svc: svc,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ParentDropdown<AreaRecord>(
            label: 'Chọn khu',
            value: svc.selectedAreaId,
            items: svc.areas,
            itemLabel: (a) => '${a.areaCode} — ${a.areaName}',
            onChanged: svc.selectArea,
          ),
          _Toolbar(
            svc: svc,
            canAdd: svc.selectedAreaId != null,
            addLabel: 'Thêm dãy',
            onAdd: svc.selectedAreaId == null
                ? null
                : () => showRowFormDialog(context, svc),
          ),
        ],
      ),
      child: _DataTableWrapper(
        loading: svc.loading,
        empty: svc.selectedAreaId == null || items.isEmpty,
        emptyMessage: svc.selectedAreaId == null
            ? 'Chọn khu để xem dãy.'
            : 'Chưa có dãy.',
        table: DataTable(
          columns: const [
            DataColumn(label: Text('Mã')),
            DataColumn(label: Text('Tên dãy')),
            DataColumn(label: Text('')),
          ],
          rows: items.map((r) {
            return DataRow(cells: [
              DataCell(Text(r.rowCode)),
              DataCell(Text(r.rowName)),
              DataCell(_rowActions(
                onEdit: () => showRowFormDialog(context, svc, existing: r),
                onDelete: () async {
                  if (!await confirmDelete(context,
                      title: 'Xóa dãy?',
                      message: '${r.rowName} (${r.rowCode})?')) return;
                  try {
                    await svc.deleteRow(r);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _BoxTab extends StatelessWidget {
  const _BoxTab({required this.svc});
  final ProductionManagementService svc;

  @override
  Widget build(BuildContext context) {
    final items = svc.filteredBoxes;
    return _TabScaffold(
      svc: svc,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ParentDropdown<AreaRecord>(
            label: 'Khu',
            value: svc.selectedAreaId,
            items: svc.areas,
            itemLabel: (a) => '${a.areaCode} — ${a.areaName}',
            onChanged: (id) {
              svc.selectArea(id);
              if (id != null) svc.loadRows();
            },
          ),
          _ParentDropdown<RowRecord>(
            label: 'Dãy',
            value: svc.selectedRowId,
            items: svc.rows,
            itemLabel: (r) => '${r.rowCode} — ${r.rowName}',
            onChanged: svc.selectRow,
          ),
          _Toolbar(
            svc: svc,
            canAdd: svc.selectedRowId != null,
            addLabel: 'Thêm hộp (1 hoặc nhiều)',
            onAdd: svc.selectedRowId == null
                ? null
                : () => showBoxFormDialog(context, svc),
          ),
        ],
      ),
      child: _DataTableWrapper(
        loading: svc.loading,
        empty: svc.selectedRowId == null || items.isEmpty,
        emptyMessage:
            svc.selectedRowId == null ? 'Chọn dãy để xem hộp.' : 'Chưa có hộp.',
        table: DataTable(
          columns: const [
            DataColumn(label: Text('Mã')),
            DataColumn(label: Text('Vị trí')),
            DataColumn(label: Text('TT')),
            DataColumn(label: Text('')),
          ],
          rows: items.map((b) {
            return DataRow(cells: [
              DataCell(Text(b.boxCode)),
              DataCell(Text(b.position ?? '—')),
              DataCell(Text(b.status)),
              DataCell(_rowActions(
                onEdit: () => showBoxFormDialog(context, svc, existing: b),
                onDelete: () async {
                  if (!await confirmDelete(context,
                      title: 'Xóa hộp?',
                      message: b.boxCode)) return;
                  try {
                    await svc.deleteBox(b);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _BatchTab extends StatelessWidget {
  const _BatchTab({required this.svc});
  final ProductionManagementService svc;

  @override
  Widget build(BuildContext context) {
    final items = svc.filteredBatches;
    return _TabScaffold(
      svc: svc,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ParentDropdown<AreaRecord>(
            label: 'Khu',
            value: svc.selectedAreaId,
            items: svc.areas,
            itemLabel: (a) => '${a.areaCode} — ${a.areaName}',
            onChanged: (id) {
              svc.selectArea(id);
              if (id != null) svc.loadRows();
            },
          ),
          _ParentDropdown<RowRecord>(
            label: 'Dãy',
            value: svc.selectedRowId,
            items: svc.rows,
            itemLabel: (r) => '${r.rowCode} — ${r.rowName}',
            onChanged: (id) {
              svc.selectRow(id);
              if (id != null) svc.loadBoxes();
            },
          ),
          _ParentDropdown<BoxRecord>(
            label: 'Hộp nuôi',
            value: svc.selectedBoxId,
            items: svc.boxes,
            itemLabel: (b) => b.boxCode,
            onChanged: svc.selectBox,
          ),
          _Toolbar(
            svc: svc,
            canAdd: svc.selectedBoxId != null,
            addLabel: 'Thêm đợt',
            onAdd: svc.selectedBoxId == null
                ? null
                : () => showBatchFormDialog(context, svc),
          ),
        ],
      ),
      child: _DataTableWrapper(
        loading: svc.loading,
        empty: svc.selectedBoxId == null || items.isEmpty,
        emptyMessage: svc.selectedBoxId == null
            ? 'Chọn hộp để xem đợt nuôi.'
            : 'Chưa có đợt.',
        table: DataTable(
          columns: const [
            DataColumn(label: Text('Mã đợt')),
            DataColumn(label: Text('Bắt đầu')),
            DataColumn(label: Text('SL')),
            DataColumn(label: Text('TT')),
            DataColumn(label: Text('')),
          ],
          rows: items.map((b) {
            return DataRow(cells: [
              DataCell(Text(b.batchCode)),
              DataCell(Text(_fmt(b.startDate))),
              DataCell(Text('${b.currentQuantity}/${b.initialQuantity}')),
              DataCell(Text(b.status)),
              DataCell(_rowActions(
                onEdit: () => showBatchFormDialog(context, svc, existing: b),
                onDelete: () async {
                  if (!await confirmDelete(context,
                      title: 'Xóa đợt?',
                      message: b.batchCode)) return;
                  try {
                    await svc.deleteBatch(b);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _CrabTab extends StatelessWidget {
  const _CrabTab({required this.svc});
  final ProductionManagementService svc;

  @override
  Widget build(BuildContext context) {
    final items = svc.filteredCrabs;
    return _TabScaffold(
      svc: svc,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ParentDropdown<BoxRecord>(
            label: 'Hộp nuôi',
            value: svc.selectedBoxId,
            items: svc.boxes,
            itemLabel: (b) => b.boxCode,
            onChanged: (id) {
              svc.selectBox(id);
              if (id != null) svc.loadBatches();
            },
          ),
          _ParentDropdown<FarmingBatchRecord>(
            label: 'Đợt nuôi',
            value: svc.selectedBatchId,
            items: svc.batches,
            itemLabel: (b) => b.batchCode,
            onChanged: svc.selectBatch,
          ),
          _Toolbar(
            svc: svc,
            canAdd: svc.selectedBatchId != null,
            addLabel: 'Thêm cua',
            onAdd: svc.selectedBatchId == null
                ? null
                : () => showCrabFormDialog(context, svc),
          ),
        ],
      ),
      child: _DataTableWrapper(
        loading: svc.loading,
        empty: svc.selectedBatchId == null || items.isEmpty,
        emptyMessage: svc.selectedBatchId == null
            ? 'Chọn đợt để xem cua.'
            : 'Chưa có cua.',
        table: DataTable(
          columns: const [
            DataColumn(label: Text('Mã')),
            DataColumn(label: Text('Giới')),
            DataColumn(label: Text('Cân (g)')),
            DataColumn(label: Text('TT')),
            DataColumn(label: Text('')),
          ],
          rows: items.map((c) {
            return DataRow(cells: [
              DataCell(Text(c.crabCode)),
              DataCell(Text(c.gender)),
              DataCell(Text(c.weight?.toStringAsFixed(1) ?? '—')),
              DataCell(Text(c.status)),
              DataCell(_rowActions(
                onEdit: () => showCrabFormDialog(context, svc, existing: c),
                onDelete: () async {
                  if (!await confirmDelete(context,
                      title: 'Xóa cua?',
                      message: c.crabCode)) return;
                  try {
                    await svc.deleteCrab(c);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _TabScaffold extends StatelessWidget {
  const _TabScaffold({
    required this.svc,
    required this.toolbar,
    required this.child,
  });

  final ProductionManagementService svc;
  final Widget toolbar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          toolbar,
          const SizedBox(height: 8),
          GlassCard(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _DataTableWrapper extends StatelessWidget {
  const _DataTableWrapper({
    required this.loading,
    required this.empty,
    required this.table,
    this.emptyMessage = 'Chưa có dữ liệu.',
  });

  final bool loading;
  final bool empty;
  final Widget table;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (empty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: table,
    );
  }
}

Widget _rowActions({
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Sửa',
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined, size: 20),
      ),
      IconButton(
        tooltip: 'Xóa',
        onPressed: onDelete,
        icon: Icon(Icons.delete_outline,
            size: 20, color: DashboardColors.risk.withValues(alpha: 0.9)),
      ),
    ],
  );
}
