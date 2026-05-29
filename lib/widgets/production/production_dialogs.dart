import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/production_models.dart';
import '../../services/production_management_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showAreaFormDialog(
  BuildContext context,
  ProductionManagementService svc, {
  AreaRecord? existing,
}) async {
  var preview = 'K-…';
  if (existing == null) {
    try {
      preview = await svc.fetchNextAreaCode();
    } catch (_) {}
  }
  await showDialog<void>(
    context: context,
    builder: (_) => _AreaFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.areaCode ?? preview,
    ),
  );
}

Future<void> showRowFormDialog(
  BuildContext context,
  ProductionManagementService svc, {
  RowRecord? existing,
}) async {
  var preview = 'D-…';
  if (existing == null && svc.selectedAreaId != null) {
    try {
      preview = await svc.fetchNextRowCode();
    } catch (_) {}
  }
  await showDialog<void>(
    context: context,
    builder: (_) => _RowFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.rowCode ?? preview,
    ),
  );
}

Future<void> showBoxFormDialog(
  BuildContext context,
  ProductionManagementService svc, {
  BoxRecord? existing,
}) async {
  var preview = 'H-…';
  if (existing == null && svc.selectedRowId != null) {
    try {
      preview = await svc.fetchNextBoxCode();
    } catch (_) {}
  }
  await showDialog<void>(
    context: context,
    builder: (_) => _BoxFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.boxCode ?? preview,
    ),
  );
}

Future<void> showBatchFormDialog(
  BuildContext context,
  ProductionManagementService svc, {
  FarmingBatchRecord? existing,
}) async {
  var preview = 'BT-…';
  if (existing == null && svc.selectedBoxId != null) {
    try {
      preview = await svc.fetchNextBatchCode();
    } catch (_) {}
  }
  await showDialog<void>(
    context: context,
    builder: (_) => _BatchFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.batchCode ?? preview,
    ),
  );
}

Future<void> showCrabFormDialog(
  BuildContext context,
  ProductionManagementService svc, {
  BatchCrabRecord? existing,
}) async {
  var preview = 'C-…';
  if (existing == null && svc.selectedBatchId != null) {
    try {
      preview = await svc.fetchNextCrabCode();
    } catch (_) {}
  }
  await showDialog<void>(
    context: context,
    builder: (_) => _CrabFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.crabCode ?? preview,
    ),
  );
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(title, style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: Text(message, style: GoogleFonts.notoSans(color: DashboardColors.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.risk),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  return ok == true;
}

class _AreaFormDialog extends StatefulWidget {
  const _AreaFormDialog({
    required this.svc,
    required this.autoCode,
    this.existing,
  });
  final ProductionManagementService svc;
  final AreaRecord? existing;
  final String autoCode;

  bool get isCreate => existing == null;

  @override
  State<_AreaFormDialog> createState() => _AreaFormDialogState();
}

class _AreaFormDialogState extends State<_AreaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.areaName ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.isCreate) {
        await widget.svc.createArea(
          areaName: _name.text.trim(),
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        );
      } else {
        await widget.svc.updateArea(widget.existing!,
            areaCode: widget.existing!.areaCode,
            areaName: _name.text.trim(),
            description: _desc.text.trim().isEmpty ? null : _desc.text.trim());
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu khu')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(widget.isCreate ? 'Thêm khu' : 'Sửa khu',
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _codeBanner(widget.autoCode, isCreate: widget.isCreate, label: 'khu'),
              _tf(_name, 'Tên khu *', required: true),
              _tf(_desc, 'Mô tả', maxLines: 2),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, _saving, _save),
    );
  }
}

class _RowFormDialog extends StatefulWidget {
  const _RowFormDialog({
    required this.svc,
    required this.autoCode,
    this.existing,
  });
  final ProductionManagementService svc;
  final RowRecord? existing;
  final String autoCode;

  bool get isCreate => existing == null;

  @override
  State<_RowFormDialog> createState() => _RowFormDialogState();
}

class _RowFormDialogState extends State<_RowFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.rowName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.isCreate) {
        await widget.svc.createRow(rowName: _name.text.trim());
      } else {
        await widget.svc.updateRow(widget.existing!,
            rowCode: widget.existing!.rowCode, rowName: _name.text.trim());
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu dãy')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(widget.isCreate ? 'Thêm dãy' : 'Sửa dãy',
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _codeBanner(widget.autoCode, isCreate: widget.isCreate, label: 'dãy'),
              _tf(_name, 'Tên dãy *', required: true),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, _saving, _save),
    );
  }
}

class _BoxFormDialog extends StatefulWidget {
  const _BoxFormDialog({
    required this.svc,
    required this.autoCode,
    this.existing,
  });
  final ProductionManagementService svc;
  final BoxRecord? existing;
  final String autoCode;

  bool get isCreate => existing == null;

  @override
  State<_BoxFormDialog> createState() => _BoxFormDialogState();
}

class _BoxFormDialogState extends State<_BoxFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pos;
  late final TextEditingController _vol;
  late String _status;
  var _saving = false;

  static const _statuses = ['empty', 'farming', 'maintenance'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _pos = TextEditingController(text: e?.position ?? '');
    _vol = TextEditingController(text: e?.volume?.toString() ?? '');
    _status = e?.status ?? 'empty';
  }

  @override
  void dispose() {
    _pos.dispose();
    _vol.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final vol = double.tryParse(_vol.text.trim());
    try {
      if (widget.isCreate) {
        await widget.svc.createBox(
          position: _pos.text.trim().isEmpty ? null : _pos.text.trim(),
          volume: vol,
          status: _status,
        );
      } else {
        await widget.svc.updateBox(widget.existing!,
            boxCode: widget.existing!.boxCode,
            position: _pos.text.trim().isEmpty ? null : _pos.text.trim(),
            volume: vol,
            status: _status);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu hộp')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(widget.isCreate ? 'Thêm hộp nuôi' : 'Sửa hộp nuôi',
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _codeBanner(widget.autoCode, isCreate: widget.isCreate, label: 'hộp'),
              _tf(_pos, 'Vị trí'),
              _tf(_vol, 'Thể tích (L)'),
              _dropdown('Trạng thái', _status, _statuses, (v) => setState(() => _status = v)),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, _saving, _save),
    );
  }
}

class _BatchFormDialog extends StatefulWidget {
  const _BatchFormDialog({
    required this.svc,
    required this.autoCode,
    this.existing,
  });
  final ProductionManagementService svc;
  final FarmingBatchRecord? existing;
  final String autoCode;

  bool get isCreate => existing == null;

  @override
  State<_BatchFormDialog> createState() => _BatchFormDialogState();
}

class _BatchFormDialogState extends State<_BatchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qty;
  late final TextEditingController _cur;
  late DateTime _start;
  DateTime? _expected;
  late String _status;
  var _saving = false;

  static const _statuses = ['active', 'harvested', 'failed'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _qty = TextEditingController(text: '${e?.initialQuantity ?? 0}');
    _cur = TextEditingController(text: '${e?.currentQuantity ?? 0}');
    _start = e?.startDate ?? DateTime.now();
    _expected = e?.expectedHarvestDate;
    _status = e?.status ?? 'active';
  }

  @override
  void dispose() {
    _qty.dispose();
    _cur.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final initial = start ? _start : (_expected ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _expected = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final iq = int.tryParse(_qty.text.trim()) ?? 0;
    final cq = int.tryParse(_cur.text.trim()) ?? iq;
    try {
      if (widget.isCreate) {
        await widget.svc.createBatch(
          startDate: _start,
          expectedHarvestDate: _expected,
          initialQuantity: iq,
          status: _status,
        );
      } else {
        await widget.svc.updateBatch(widget.existing!,
            batchCode: widget.existing!.batchCode,
            startDate: _start,
            expectedHarvestDate: _expected,
            actualHarvestDate: widget.existing!.actualHarvestDate,
            initialQuantity: iq,
            currentQuantity: cq,
            status: _status);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu đợt nuôi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(widget.isCreate ? 'Thêm đợt nuôi' : 'Sửa đợt nuôi',
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _codeBanner(widget.autoCode, isCreate: widget.isCreate, label: 'đợt'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Ngày bắt đầu', style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12)),
                  subtitle: Text(_fmt(_start), style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
                  trailing: IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _pickDate(true)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Dự kiến thu hoạch', style: GoogleFonts.notoSans(color: DashboardColors.textMuted, fontSize: 12)),
                  subtitle: Text(_expected == null ? '—' : _fmt(_expected!), style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
                  trailing: IconButton(icon: const Icon(Icons.event), onPressed: () => _pickDate(false)),
                ),
                _tf(_qty, 'Số lượng ban đầu *', required: true),
                if (!widget.isCreate) _tf(_cur, 'Số lượng hiện tại *', required: true),
                _dropdown('Trạng thái', _status, _statuses, (v) => setState(() => _status = v)),
              ],
            ),
          ),
        ),
      ),
      actions: _dialogActions(context, _saving, _save),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _CrabFormDialog extends StatefulWidget {
  const _CrabFormDialog({
    required this.svc,
    required this.autoCode,
    this.existing,
  });
  final ProductionManagementService svc;
  final BatchCrabRecord? existing;
  final String autoCode;

  bool get isCreate => existing == null;

  @override
  State<_CrabFormDialog> createState() => _CrabFormDialogState();
}

class _CrabFormDialogState extends State<_CrabFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight;
  late final TextEditingController _shell;
  late String _gender;
  late String _status;
  var _saving = false;

  static const _genders = ['unknown', 'male', 'female'];
  static const _statuses = ['alive', 'dead', 'molting', 'harvested'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _weight = TextEditingController(text: e?.weight?.toString() ?? '');
    _shell = TextEditingController(text: e?.shellWidth?.toString() ?? '');
    _gender = e?.gender ?? 'unknown';
    _status = e?.status ?? 'alive';
  }

  @override
  void dispose() {
    _weight.dispose();
    _shell.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final w = double.tryParse(_weight.text.trim());
    final s = double.tryParse(_shell.text.trim());
    try {
      if (widget.isCreate) {
        await widget.svc.createCrab(
          gender: _gender,
          weight: w,
          shellWidth: s,
          status: _status,
        );
      } else {
        await widget.svc.updateCrab(widget.existing!,
            crabCode: widget.existing!.crabCode,
            gender: _gender,
            weight: w,
            shellWidth: s,
            status: _status);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu cua')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(widget.isCreate ? 'Thêm cua' : 'Sửa cua',
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _codeBanner(widget.autoCode, isCreate: widget.isCreate, label: 'cua'),
              _dropdown('Giới tính', _gender, _genders, (v) => setState(() => _gender = v)),
              _tf(_weight, 'Cân nặng (g)'),
              _tf(_shell, 'Bề ngang mai (cm)'),
              _dropdown('Trạng thái', _status, _statuses, (v) => setState(() => _status = v)),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, _saving, _save),
    );
  }
}

Widget _codeBanner(String code, {required bool isCreate, required String label}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: DashboardColors.cyan.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: DashboardColors.cardBorder),
    ),
    child: Row(
      children: [
        Icon(Icons.tag_outlined, size: 20, color: DashboardColors.cyan),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCreate ? 'Mã $label (tự động)' : 'Mã $label',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textMuted,
                  fontSize: 11,
                ),
              ),
              Text(
                code,
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

List<Widget> _dialogActions(BuildContext context, bool saving, VoidCallback onSave) => [
      TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Hủy')),
      FilledButton(
        onPressed: saving ? null : onSave,
        style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
        child: saving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Lưu'),
      ),
    ];

Widget _tf(TextEditingController c, String label, {bool required = false, int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      maxLines: maxLines,
      style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
      ),
    ),
  );
}

Widget _dropdown(String label, String value, List<String> options, ValueChanged<String> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: value,
      dropdownColor: DashboardColors.card,
      style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        filled: true,
        fillColor: DashboardColors.darkNavy.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
}
