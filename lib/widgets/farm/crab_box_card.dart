import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/box_status.dart';
import '../../models/crab_box.dart';
import '../../theme/dashboard_theme.dart';

class CrabBoxCard extends StatelessWidget {
  const CrabBoxCard({
    super.key,
    required this.box,
    required this.onTap,
    this.highlighted = false,
  });

  final CrabBox box;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = box.status.color;
    final dimmed = box.status == BoxStatus.empty ||
        box.status == BoxStatus.deceased;
    final showHealth =
        box.healthScore != null && box.status != BoxStatus.empty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: DashboardColors.card.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlighted
                  ? DashboardColors.purple
                  : color.withValues(alpha: dimmed ? 0.25 : 0.55),
              width: highlighted ? 2 : 1,
            ),
            boxShadow: dimmed
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth,
                    maxHeight: constraints.maxHeight,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            box.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSans(
                              color: dimmed
                                  ? DashboardColors.textMuted
                                  : DashboardColors.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets,
                                size: 15,
                                color:
                                    dimmed ? DashboardColors.textMuted : color,
                              ),
                              if (showHealth) ...[
                                const SizedBox(width: 2),
                                Text(
                                  '${box.healthScore}',
                                  style: GoogleFonts.notoSans(
                                    color: color.withValues(alpha: 0.85),
                                    fontSize: 7,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            box.status.shortLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSans(
                              color: color,
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      if (box.hasAlert)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 9,
                            color: BoxStatus.alert.color,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
