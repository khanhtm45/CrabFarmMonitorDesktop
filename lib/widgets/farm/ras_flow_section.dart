import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/crab_box.dart';
import '../../theme/dashboard_theme.dart';
import '../dashboard/glass_card.dart';

class RasFlowSection extends StatelessWidget {
  const RasFlowSection({super.key, required this.components});

  final List<RasComponent> components;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sơ Đồ Hệ Thống RAS',
                style: GoogleFonts.notoSans(
                  color: DashboardColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: DashboardColors.healthy,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live Circulation',
                    style: GoogleFonts.notoSans(
                      color: DashboardColors.healthy,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < components.length; i++) ...[
                  _RasNode(component: components[i]),
                  if (i < components.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward,
                        color: DashboardColors.cyan.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RasNode extends StatelessWidget {
  const _RasNode({required this.component});

  final RasComponent component;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardColors.darkNavy.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DashboardColors.cyan.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(component.icon, color: DashboardColors.cyan, size: 20),
          const SizedBox(height: 6),
          Text(
            component.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: DashboardColors.healthy.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Online',
              style: GoogleFonts.notoSans(
                color: DashboardColors.healthy,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            component.metric,
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
    );
  }
}
