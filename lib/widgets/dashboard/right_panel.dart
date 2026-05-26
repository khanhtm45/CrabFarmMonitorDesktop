import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_dashboard_data.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/ai_assistant_avatar.dart';
import 'glass_card.dart';

class EnvironmentPanel extends StatelessWidget {
  const EnvironmentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Chất lượng nước',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DashboardColors.healthy.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DashboardColors.healthy.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Tốt',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.healthy,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Chất lượng nước hiện tại',
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          ...MockDashboardData.environmentParams.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EnvRow(param: p),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvRow extends StatelessWidget {
  const _EnvRow({required this.param});

  final EnvParameter param;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(param.icon, size: 18, color: DashboardColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            param.label,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          param.value,
          style: GoogleFonts.notoSans(
            color: DashboardColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: param.status.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            param.status.label,
            style: GoogleFonts.notoSans(
              color: param.status.color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class DeviceAlertSummary extends StatelessWidget {
  const DeviceAlertSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.router_outlined,
                  color: DashboardColors.blue,
                  size: 22,
                ),
                const SizedBox(height: 12),
                Text(
                  'Thiết bị hoạt động',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  MockDashboardData.devicesOnline,
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            highlight: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: DashboardColors.monitoring,
                  size: 22,
                ),
                const SizedBox(height: 12),
                Text(
                  'Cảnh báo mới',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${MockDashboardData.alertCount}',
                  style: GoogleFonts.notoSans(
                    color: DashboardColors.monitoring,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
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

class AlertsPanel extends StatelessWidget {
  const AlertsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: DashboardColors.monitoring, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cảnh báo',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...MockDashboardData.alerts.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ ', style: GoogleFonts.notoSans(fontSize: 13)),
                  Expanded(
                    child: Text(
                      a.message,
                      style: GoogleFonts.notoSans(
                        color: a.severity.color,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CrabAssistantCard extends StatefulWidget {
  const CrabAssistantCard({super.key, required this.healthScore});

  final int healthScore;

  @override
  State<CrabAssistantCard> createState() => _CrabAssistantCardState();
}

class _CrabAssistantCardState extends State<CrabAssistantCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;
  bool _eyesOpen = true;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _eyesOpen = false);
          Future.delayed(const Duration(milliseconds: 120), () {
            if (mounted) setState(() => _eyesOpen = true);
          });
          _blinkController.forward(from: 0);
        }
      });
    _blinkController.forward();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = mascotMoodFromHealth(widget.healthScore);
    final moodColor = switch (mood) {
      MascotMood.happy => DashboardColors.healthy,
      MascotMood.calm => DashboardColors.cyan,
      MascotMood.alert => DashboardColors.monitoring,
      MascotMood.critical => DashboardColors.risk,
    };

    return GlassCard(
      borderColor: DashboardColors.purple.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: moodColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: moodColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const AiAssistantAvatar(
                      size: 56,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.all(Radius.circular(28)),
                    ),
                  ),
                  if (!_eyesOpen)
                    Positioned(
                      top: 18,
                      child: Container(
                        width: 36,
                        height: 4,
                        color: DashboardColors.card.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crab Assistant',
                      style: GoogleFonts.notoSans(
                        color: DashboardColors.purple,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _moodLabel(mood),
                      style: GoogleFonts.notoSans(
                        color: moodColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            MockDashboardData.assistantMessage(widget.healthScore),
            style: GoogleFonts.notoSans(
              color: DashboardColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Thực hiện ngay',
                    style: GoogleFonts.notoSans(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DashboardColors.textMuted,
                    side: BorderSide(color: DashboardColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Bỏ qua',
                    style: GoogleFonts.notoSans(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _moodLabel(MascotMood mood) => switch (mood) {
        MascotMood.happy => 'Trạng thái: Vui vẻ',
        MascotMood.calm => 'Trạng thái: Bình thường',
        MascotMood.alert => 'Trạng thái: Cảnh giác',
        MascotMood.critical => 'Trạng thái: Khẩn cấp',
      };
}
