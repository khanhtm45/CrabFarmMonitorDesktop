import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/farm_record.dart';
import '../../services/farm_management_service.dart';
import '../../theme/dashboard_theme.dart';

Future<void> showCreateFarmDialog(
  BuildContext context,
  FarmManagementService service,
) async {
  String previewCode = 'FR-…';
  try {
    previewCode = await service.fetchNextCode();
  } catch (_) {}

  await _showFarmFormDialog(
    context: context,
    title: 'Thêm trại mới',
    autoCode: previewCode,
    onSubmit: (name, address, description) => service.create(
      name: name,
      address: address,
      description: description,
    ),
  );
}

Future<void> showEditFarmDialog(
  BuildContext context,
  FarmManagementService service,
  FarmRecord farm,
) async {
  await _showFarmFormDialog(
    context: context,
    title: 'Sửa trại',
    autoCode: farm.code,
    initialName: farm.name,
    initialAddress: farm.address,
    initialDescription: farm.description,
    onSubmit: (name, address, description) => service.update(
      farm,
      name: name,
      address: address,
      description: description,
    ),
  );
}

Future<void> showDeleteFarmDialog(
  BuildContext context,
  FarmManagementService service,
  FarmRecord farm,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text(
        'Xóa trại?',
        style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      ),
      content: Text(
        'Xóa "${farm.name}" (${farm.code})? Hành động không hoàn tác.',
        style: GoogleFonts.notoSans(color: DashboardColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.risk),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  try {
    await service.delete(farm);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa trại')),
      );
    }
  } on Exception catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}

Future<void> _showFarmFormDialog({
  required BuildContext context,
  required String title,
  required Future<dynamic> Function(
    String name,
    String? address,
    String? description,
  ) onSubmit,
  required String autoCode,
  String? initialName,
  String? initialAddress,
  String? initialDescription,
}) async {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: initialName ?? '');
  final addressCtrl = TextEditingController(text: initialAddress ?? '');
  final descCtrl = TextEditingController(text: initialDescription ?? '');
  var saving = false;
  final isCreate = initialName == null;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        backgroundColor: DashboardColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _autoCodeBanner(autoCode, isCreate: isCreate),
                  _field(nameCtrl, 'Tên trại *', required: true),
                  _field(addressCtrl, 'Địa chỉ', maxLines: 2),
                  _field(descCtrl, 'Mô tả', maxLines: 3),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialog(() => saving = true);
                    try {
                      await onSubmit(
                        nameCtrl.text.trim(),
                        addressCtrl.text.trim().isEmpty
                            ? null
                            : addressCtrl.text.trim(),
                        descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isCreate ? 'Đã thêm trại' : 'Đã cập nhật trại',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    } finally {
                      if (ctx.mounted) setDialog(() => saving = false);
                    }
                  },
            style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
        ],
      ),
    ),
  );

  nameCtrl.dispose();
  addressCtrl.dispose();
  descCtrl.dispose();
}

Widget _autoCodeBanner(String code, {required bool isCreate}) {
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
                isCreate ? 'Mã trại (tự động)' : 'Mã trại',
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

Widget _field(
  TextEditingController ctrl,
  String label, {
  int maxLines = 1,
  bool required = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.notoSans(color: DashboardColors.textPrimary),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null
          : null,
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
