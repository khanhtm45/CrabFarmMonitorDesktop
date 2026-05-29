import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/area_status.dart';
import '../../models/production_models.dart';
import '../../services/area_management_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showAreaFormDialog(
  BuildContext context,
  AreaManagementService svc, {
  AreaRecord? existing,
}) async {
  var preview = 'K-…';
  if (existing == null) {
    try {
      preview = await svc.fetchNextAreaCode();
    } catch (_) {}
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _AreaFormDialog(
      svc: svc,
      existing: existing,
      autoCode: existing?.areaCode ?? preview,
    ),
  );
}

class _AreaFormDialog extends StatefulWidget {
  const _AreaFormDialog({
    required this.svc,
    required this.autoCode,
    this.existing,
  });

  final AreaManagementService svc;
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
  late String _status;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.areaName ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _status = e?.status ?? 'active';
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSans(color: DashboardColors.textMuted),
        filled: true,
        fillColor: DashboardColors.darkNavy,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardColors.cardBorder),
        ),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.isCreate) {
        await widget.svc.createArea(
          areaName: _name.text.trim(),
          description:
              _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          status: _status,
        );
      } else {
        await widget.svc.updateArea(
          widget.existing!,
          areaName: _name.text.trim(),
          description:
              _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          status: _status,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.isCreate ? 'Đã thêm khu' : 'Đã cập nhật khu'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DashboardColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.isCreate ? 'Thêm khu' : 'Cập nhật khu',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  readOnly: true,
                  initialValue: widget.autoCode,
                  decoration: _dec('Mã khu'),
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: _dec('Tên khu *'),
                  style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nhập tên khu' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: _dec('Mô tả'),
                  style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: _dec('Trạng thái'),
                  dropdownColor: DashboardColors.card,
                  style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                    DropdownMenuItem(
                        value: 'maintenance', child: Text('Bảo trì')),
                    DropdownMenuItem(
                        value: 'disabled', child: Text('Ngưng sử dụng')),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Lưu'),
                      style: FilledButton.styleFrom(
                        backgroundColor: DashboardColors.seaGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
