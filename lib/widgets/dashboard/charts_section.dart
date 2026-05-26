import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mock_dashboard_data.dart';
import '../../services/dashboard_env_trend_service.dart';
import '../../theme/dashboard_theme.dart';
import '../shared/ph_temp_line_chart.dart';
import 'glass_card.dart';

class ChartsSection extends StatefulWidget {
  const ChartsSection({super.key});

  @override
  State<ChartsSection> createState() => _ChartsSectionState();
}

class _ChartsSectionState extends State<ChartsSection> {
  final _envTrend = DashboardEnvTrendService();

  @override
  void initState() {
    super.initState();
    _envTrend.addListener(_onTrend);
    _envTrend.start();
  }

  @override
  void dispose() {
    _envTrend.removeListener(_onTrend);
    _envTrend.dispose();
    super.dispose();
  }

  void _onTrend() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 900;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: PhTempChartCard(trend: _envTrend)),
                  const SizedBox(width: 16),
                  const Expanded(child: DoBarChartCard()),
                ],
              );
            }
            return Column(
              children: [
                PhTempChartCard(trend: _envTrend),
                const SizedBox(height: 16),
                const DoBarChartCard(),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 900;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: TempLineChartCard(trend: _envTrend)),
                  const SizedBox(width: 16),
                  const Expanded(child: GrowthBarChartCard()),
                ],
              );
            }
            return Column(
              children: [
                TempLineChartCard(trend: _envTrend),
                const SizedBox(height: 16),
                const GrowthBarChartCard(),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        const HealthMultiLineChartCard(),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.legend,
    this.chartHeight = 200,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? legend;
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSans(
              color: DashboardColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.notoSans(
                color: DashboardColors.healthy,
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (child is PhTempLineChart) child else SizedBox(height: chartHeight, child: child),
          if (legend != null) ...[
            const SizedBox(height: 12),
            Center(child: legend!),
          ],
        ],
      ),
    );
  }
}

class PhTempChartCard extends StatelessWidget {
  const PhTempChartCard({super.key, required this.trend});

  final DashboardEnvTrendService trend;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Biểu đồ pH & Nhiệt độ (Cloud ~30 phút)',
      subtitle: 'Realtime · cửa sổ 30 phút · cập nhật 3s',
      chartHeight: 260,
      legend: const PhTempChartLegend(),
      child: PhTempLineChart(
        points: trend.points,
        rangeMinutes: trend.rangeMinutesValue,
      ),
    );
  }
}

class TempLineChartCard extends StatelessWidget {
  const TempLineChartCard({super.key, required this.trend});

  final DashboardEnvTrendService trend;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Nhiệt độ (Cloud ~30 phút)',
      subtitle: 'Realtime · cập nhật 3s',
      chartHeight: 260,
      legend: const PhTempChartLegend(showPh: false),
      child: PhTempLineChart(
        points: trend.points,
        rangeMinutes: trend.rangeMinutesValue,
        showPh: false,
        showTemp: true,
      ),
    );
  }
}

class DoBarChartCard extends StatelessWidget {
  const DoBarChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final data = MockDashboardData.do24h;
    return _ChartCard(
      title: 'Mức Oxy hòa tan (DO)',
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 7,
          minY: 5,
          gridData: _gridData(),
          borderData: FlBorderData(show: false),
          titlesData: _titlesData(),
          barGroups: List.generate(data.length, (i) {
            final highlight = i == 7;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i],
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: highlight
                        ? [DashboardColors.monitoring, DashboardColors.molting]
                        : [DashboardColors.blue, DashboardColors.cyan],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class GrowthBarChartCard extends StatelessWidget {
  const GrowthBarChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final data = MockDashboardData.growthBars;
    return _ChartCard(
      title: 'Tăng trưởng cua',
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 300,
          gridData: _gridData(),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: _axisStyle(),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Text('T${i + 1}', style: _axisStyle());
                },
              ),
            ),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          barGroups: List.generate(
            data.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i],
                  width: 18,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  gradient: DashboardColors.accentGradient,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HealthMultiLineChartCard extends StatefulWidget {
  const HealthMultiLineChartCard({super.key});

  @override
  State<HealthMultiLineChartCard> createState() =>
      _HealthMultiLineChartCardState();
}

class _HealthMultiLineChartCardState extends State<HealthMultiLineChartCard> {
  final _visible = [true, true, true, true];

  static const _series = [
    ('Lứa 01', DashboardColors.cyan),
    ('Lứa 02', DashboardColors.blue),
    ('Lứa 03', DashboardColors.purple),
    ('Toàn trại', DashboardColors.healthy),
  ];

  @override
  Widget build(BuildContext context) {
    final datasets = [
      MockDashboardData.batch01Health,
      MockDashboardData.batch02Health,
      MockDashboardData.batch03Health,
      MockDashboardData.farmHealth,
    ];

    return _ChartCard(
      title: 'Health Score Theo Thời Gian',
      legend: Wrap(
        spacing: 8,
        children: List.generate(_series.length, (i) {
          final (label, color) = _series[i];
          return FilterChip(
            label: Text(label, style: GoogleFonts.notoSans(fontSize: 10)),
            selected: _visible[i],
            onSelected: (v) => setState(() => _visible[i] = v),
            selectedColor: color.withValues(alpha: 0.25),
            checkmarkColor: color,
            labelStyle: TextStyle(color: _visible[i] ? color : DashboardColors.textMuted),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }),
      ),
      child: LineChart(
        LineChartData(
          minY: 80,
          maxY: 100,
          gridData: _gridData(),
          borderData: FlBorderData(show: false),
          titlesData: _titlesData(),
          lineBarsData: [
            for (var i = 0; i < datasets.length; i++)
              if (_visible[i])
                _lineBar(datasets[i], _series[i].$2),
          ],
        ),
      ),
    );
  }
}

LineChartBarData _lineBar(List<double> data, Color color) {
  return LineChartBarData(
    spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
    isCurved: true,
    color: color,
    barWidth: 3,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.02),
        ],
      ),
    ),
  );
}

FlGridData _gridData() => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) => FlLine(
        color: DashboardColors.cardBorder.withValues(alpha: 0.5),
        strokeWidth: 1,
      ),
    );

FlTitlesData _titlesData() => FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          getTitlesWidget: (v, _) => Text(
            v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1),
            style: _axisStyle(),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 2,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= MockDashboardData.chartLabels.length) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                MockDashboardData.chartLabels[i],
                style: _axisStyle(),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
    );

TextStyle _axisStyle() => GoogleFonts.notoSans(
      color: DashboardColors.textMuted,
      fontSize: 9,
    );
