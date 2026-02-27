import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/core/constants/string_constants.dart';
import 'package:voicesewa_worker/features/earnings/providers/earnings_provider.dart';

class EarningsChart extends ConsumerWidget {
  const EarningsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(earningsDataProvider);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: earningsAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Could not load chart',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ),
          data: (data) => _ChartContent(data: data),
        ),
      ),
    );
  }
}

class _ChartContent extends StatefulWidget {
  final EarningsData data;
  const _ChartContent({required this.data});

  @override
  State<_ChartContent> createState() => _ChartContentState();
}

class _ChartContentState extends State<_ChartContent> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final months = widget.data.monthlyEarnings;
    final totalEarned = widget.data.totalEarned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earnings Overview',
                  style: TextStyle(
                    color: ColorConstants.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All time · ${months.length} month${months.length != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColorConstants.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${StringConstants.rupee}${totalEarned.toInt()}',
                style: TextStyle(
                  color: ColorConstants.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Empty state ───────────────────────────────────────────────────
        if (months.isEmpty)
          SizedBox(
            height: 160,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No earnings data yet',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(height: 180, child: LineChart(_buildChartData(months))),

        const SizedBox(height: 8),

        // ── X-axis label hint ─────────────────────────────────────────────
        if (months.isNotEmpty && months.length > 6)
          Center(
            child: Text(
              '${months.first.fullLabel}  →  ${months.last.fullLabel}',
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ),
      ],
    );
  }

  LineChartData _buildChartData(List<MonthlyEarning> months) {
    final maxY = months.map((m) => m.amount).reduce((a, b) => a > b ? a : b);
    final spots = months
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.amount))
        .toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1000,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1000,
            getTitlesWidget: (value, _) => Text(
              '₹${_formatAmount(value)}',
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: months.length <= 6
                ? 1
                : (months.length / 6).ceilToDouble(),
            getTitlesWidget: (value, _) {
              final idx = value.toInt();
              if (idx < 0 || idx >= months.length) {
                return const SizedBox.shrink();
              }
              final m = months[idx];
              // Show "Jan\n2024" only when year changes or first point
              final showYear = idx == 0 || months[idx - 1].year != m.year;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  showYear ? '${m.monthLabel}\n${m.year}' : m.monthLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (months.length - 1).toDouble(),
      minY: 0,
      maxY: maxY * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: ColorConstants.primaryBlue,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, index) {
              final isTouched = index == _touchedIndex;
              return FlDotCirclePainter(
                radius: isTouched ? 6 : 3,
                color: isTouched ? Colors.white : ColorConstants.primaryBlue,
                strokeWidth: isTouched ? 2.5 : 0,
                strokeColor: ColorConstants.primaryBlue,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                ColorConstants.primaryBlue.withOpacity(0.18),
                ColorConstants.primaryBlue.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchCallback: (event, response) {
          setState(() {
            _touchedIndex = response?.lineBarSpots?.first.spotIndex;
          });
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => ColorConstants.primaryBlue,
          getTooltipItems: (spots) => spots
              .map(
                (s) => LineTooltipItem(
                  '${months[s.spotIndex].fullLabel}\n'
                  '${StringConstants.rupee}${s.y.toInt()}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _formatAmount(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toInt().toString();
  }
}
