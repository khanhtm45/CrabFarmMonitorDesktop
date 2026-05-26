import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/feed_service.dart';
import '../../theme/dashboard_theme.dart';

const _areas = ['Khu A', 'Khu B', 'Khu C'];
const _batches = ['CFM-2026-001', 'CFM-2026-002', 'CFM-2026-003'];
const _feeds = [
  'Thức ăn viên 40% đạm',
  'Cá tạp',
  'Thức ăn viên Bio-Growth',
];
const _times = ['06:00', '08:00', '12:00', '13:00', '18:00', '20:00'];
const _repeatRules = ['Hàng ngày', 'Thứ 2 – Thứ 6', 'Cuối tuần', 'Một lần'];

Future<void> showCreateFeedingScheduleDialog(
  BuildContext context,
  FeedService service,
) {
  var selectedDate = service.selectedDay;
  var time = '08:00';
  var area = _areas.first;
  var batch = _batches.first;
  var feed = _feeds.first;
  var repeat = _repeatRules.first;
  final portionCtrl = TextEditingController(text: '12');

  return showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        return AlertDialog(
          backgroundColor: DashboardColors.card,
          title: Text(
            'Tạo lịch cho ăn',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Ngày: ${selectedDate.day.toString().padLeft(2, '0')}/'
                      '${selectedDate.month.toString().padLeft(2, '0')}/'
                      '${selectedDate.year}',
                      style: GoogleFonts.notoSans(fontSize: 13),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2026, 1, 1),
                        lastDate: DateTime(2027, 12, 31),
                      );
                      if (picked != null) {
                        setLocal(() => selectedDate = picked);
                      }
                    },
                  ),
                  _dropdown(
                    label: 'Giờ cho ăn',
                    value: time,
                    items: _times,
                    onChanged: (v) => setLocal(() => time = v!),
                  ),
                  _dropdown(
                    label: 'Khu nuôi',
                    value: area,
                    items: _areas,
                    onChanged: (v) => setLocal(() => area = v!),
                  ),
                  _dropdown(
                    label: 'Lứa nuôi',
                    value: batch,
                    items: _batches,
                    onChanged: (v) => setLocal(() => batch = v!),
                  ),
                  _dropdown(
                    label: 'Loại thức ăn',
                    value: feed,
                    items: _feeds,
                    onChanged: (v) => setLocal(() => feed = v!),
                  ),
                  TextField(
                    controller: portionCtrl,
                    decoration: const InputDecoration(labelText: 'Khẩu phần (kg)'),
                    keyboardType: TextInputType.number,
                  ),
                  _dropdown(
                    label: 'Lặp lại',
                    value: repeat,
                    items: _repeatRules,
                    onChanged: (v) => setLocal(() => repeat = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                service.addSchedule(
                  date: selectedDate,
                  time: time,
                  area: area,
                  batchId: batch,
                  feedName: feed,
                  portionKg: double.tryParse(portionCtrl.text) ?? 12,
                  repeatRule: repeat,
                );
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
              child: const Text('Tạo lịch'),
            ),
          ],
        );
      },
    ),
  );
}

Widget _dropdown({
  required String label,
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    ),
  );
}

Future<void> showFeedImportDialog(BuildContext context, FeedService service) {
  final codeCtrl = TextEditingController(text: 'FEED-001');
  final qtyCtrl = TextEditingController(text: '50');

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text('Nhập kho', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: codeCtrl,
            decoration: const InputDecoration(labelText: 'Mã thức ăn'),
          ),
          TextField(
            controller: qtyCtrl,
            decoration: const InputDecoration(labelText: 'Số lượng (kg)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton(
          onPressed: () {
            final kg = double.tryParse(qtyCtrl.text) ?? 0;
            service.importStock(codeCtrl.text.trim(), kg);
            Navigator.pop(ctx);
          },
          style: FilledButton.styleFrom(backgroundColor: DashboardColors.purple),
          child: const Text('Lưu nhập kho'),
        ),
      ],
    ),
  );
}

Future<void> showFeedExportDialog(BuildContext context, FeedService service) {
  final codeCtrl = TextEditingController(text: 'FEED-001');
  final qtyCtrl = TextEditingController(text: '10');

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DashboardColors.card,
      title: Text('Xuất kho', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: codeCtrl,
            decoration: const InputDecoration(labelText: 'Mã thức ăn'),
          ),
          TextField(
            controller: qtyCtrl,
            decoration: const InputDecoration(labelText: 'Số lượng xuất (kg)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton(
          onPressed: () {
            final kg = double.tryParse(qtyCtrl.text) ?? 0;
            service.exportStock(codeCtrl.text.trim(), kg);
            Navigator.pop(ctx);
          },
          child: const Text('Xác nhận xuất'),
        ),
      ],
    ),
  );
}
