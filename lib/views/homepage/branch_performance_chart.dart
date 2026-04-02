import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/branch_performance_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/branch_performance_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class BranchPerformanceChart extends StatefulWidget {
  const BranchPerformanceChart({super.key});

  @override
  State<BranchPerformanceChart> createState() => _BranchPerformanceChartState();
}

class _BranchPerformanceChartState extends State<BranchPerformanceChart> {
  bool _showChart = true;

  static const _bgColor = Color(0xff232d37);
  static const _dividerColor = Color(0xff37434d);
  static const _mutedColor = Color(0xff68737d);

  static const List<Color> _branchColors = [
    Color(0xFF2196F3),
    Color(0xFFDF6E98),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF8BC34A),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
  ];

  List<String> _getAllBranches(BranchPerformanceData? data) {
    final List<String> branches = [];
    for (final day in data?.last7Days ?? []) {
      for (final b in day.data ?? []) {
        if (b.branchName != null && !branches.contains(b.branchName!)) {
          branches.add(b.branchName!);
        }
      }
    }
    return branches;
  }

  Color _colorForBranch(List<String> branches, String branchName) {
    final index = branches.indexOf(branchName);
    return _branchColors[index % _branchColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BranchPerformanceController>(
      builder: (context, controller, _) {
        final data = controller.branchPerformanceResponse?.data;
        final branches = _getAllBranches(data);

        return Container(
          decoration: const BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, branches),
              if (branches.isNotEmpty) _buildLegendRow(branches),
              _buildMonthlyTotals(data),
              Divider(color: _dividerColor, height: 1),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  screenPadding * 1.5,
                  screenPadding,
                  screenPadding * 1.5,
                  screenPadding,
                ),
                child: _showChart ? _buildChart(data, branches) : _buildTable(data, branches),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, List<String> branches) {
    return Padding(
      padding: EdgeInsets.fromLTRB(screenPadding, screenPadding * 0.75, screenPadding * 0.75, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Branch Performance – Past 7 Days',
            style: AppTypography.displayMedium(context).apply(color: Colors.white),
          ),
          _buildToggle(),
        ],
      ),
    );
  }

  Widget _buildLegendRow(List<String> branches) {
    return Padding(
      padding: EdgeInsets.fromLTRB(screenPadding, 8, screenPadding, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: branches.map((b) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _colorForBranch(branches, b),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(b, style: const TextStyle(color: _mutedColor, fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthlyTotals(BranchPerformanceData? data) {
    final months = data?.last3Months ?? [];
    if (months.isEmpty) return const SizedBox();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff1c2630),
        border: Border.symmetric(horizontal: BorderSide(color: _dividerColor, width: 1)),
      ),
      padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 10),
      child: Row(
        children: [
          const Text(
            'Monthly Total',
            style: TextStyle(color: _mutedColor, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          ...months.map((month) {
            return Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xff2a3a4a),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${month.mmm ?? ''} ${month.yyyy ?? ''}',
                    style: const TextStyle(color: _mutedColor, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${month.total ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'appointments',
                    style: TextStyle(color: _mutedColor, fontSize: 9),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _dividerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleOption(Icons.bar_chart_rounded, true),
          _toggleOption(Icons.table_chart_outlined, false),
        ],
      ),
    );
  }

  Widget _toggleOption(IconData icon, bool isChart) {
    final selected = _showChart == isChart;
    return GestureDetector(
      onTap: () => setState(() => _showChart = isChart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2196F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: selected ? Colors.white : _mutedColor, size: 18),
      ),
    );
  }

  Widget _buildChart(BranchPerformanceData? data, List<String> branches) {
    if (data == null || (data.last7Days?.isEmpty ?? true)) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available', style: TextStyle(color: _mutedColor))),
      );
    }

    final days = data.last7Days!;
    final maxY = days.fold<double>(
      0,
      (max, d) => (d.total ?? 0).toDouble() > max ? (d.total ?? 0).toDouble() : max,
    );

    return AspectRatio(
      aspectRatio: isMobile ? 1.8 : 4,
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 10 : maxY * 1.3,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey.withAlpha(opacityCalculation(.85)),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = days[group.x];
                final buffer = StringBuffer('${day.dd} ${day.mmm}\n');
                for (final b in branches) {
                  final count = day.data
                          ?.firstWhere(
                            (bc) => bc.branchName == b,
                            orElse: () => BranchCount(branchName: b, totalAppointments: 0),
                          )
                          .totalAppointments ??
                      0;
                  if (count > 0) buffer.write('$b: $count\n');
                }
                buffer.write('Total: ${day.total ?? 0}');
                return BarTooltipItem(
                  buffer.toString(),
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == 0) return const SizedBox();
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: _mutedColor, fontSize: 11),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= days.length) return const SizedBox();
                  final day = days[index];
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      '${day.dd}\n${day.mmm}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _mutedColor, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: _dividerColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(days.length, (i) {
            final day = days[i];
            double yFrom = 0;
            final stackItems = branches.map((b) {
              final count = (day.data
                          ?.firstWhere(
                            (bc) => bc.branchName == b,
                            orElse: () => BranchCount(branchName: b, totalAppointments: 0),
                          )
                          .totalAppointments ??
                      0)
                  .toDouble();
              final item = BarChartRodStackItem(yFrom, yFrom + count, _colorForBranch(branches, b));
              yFrom += count;
              return item;
            }).toList();

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (day.total ?? 0).toDouble(),
                  rodStackItems: stackItems,
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  color: Colors.transparent,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTable(BranchPerformanceData? data, List<String> branches) {
    if (data == null || branches.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No data available', style: TextStyle(color: _mutedColor))),
      );
    }

    const headerStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11);
    const cellStyle = TextStyle(color: _mutedColor, fontSize: 12);
    const totalStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12);

    final days = data.last7Days ?? [];
    final months = data.last3Months ?? [];

    Widget branchCell(String name) {
      return Container(
        height: 28,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _colorForBranch(branches, name),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(name, style: cellStyle),
          ],
        ),
      );
    }

    Widget sectionHeader(String label, Color color) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      );
    }

    List<Widget> buildDayColumns() {
      return days.map((day) {
        return Column(
          children: [
            Container(
              width: 52,
              height: 24,
              alignment: Alignment.center,
              child: Text(
                '${day.dd}\n${day.mmm}',
                textAlign: TextAlign.center,
                style: headerStyle.copyWith(fontSize: 10),
              ),
            ),
            ...branches.map((b) {
              final count = day.data
                      ?.firstWhere(
                        (bc) => bc.branchName == b,
                        orElse: () => BranchCount(branchName: b, totalAppointments: 0),
                      )
                      .totalAppointments ??
                  0;
              return Container(
                width: 52,
                height: 28,
                alignment: Alignment.center,
                child: Text('$count', style: cellStyle),
              );
            }),
            Container(
              width: 52,
              height: 28,
              alignment: Alignment.center,
              child: Text('${day.total ?? 0}', style: totalStyle),
            ),
          ],
        );
      }).toList();
    }

    List<Widget> buildMonthColumns() {
      return months.map((month) {
        return Column(
          children: [
            Container(
              width: 64,
              height: 24,
              alignment: Alignment.center,
              child: Text(
                '${month.mmm}\n${month.yyyy}',
                textAlign: TextAlign.center,
                style: headerStyle.copyWith(fontSize: 10),
              ),
            ),
            ...branches.map((b) {
              final count = month.data
                      ?.firstWhere(
                        (bc) => bc.branchName == b,
                        orElse: () => BranchCount(branchName: b, totalAppointments: 0),
                      )
                      .totalAppointments ??
                  0;
              return Container(
                width: 64,
                height: 28,
                alignment: Alignment.center,
                child: Text('$count', style: cellStyle),
              );
            }),
            Container(
              width: 64,
              height: 28,
              alignment: Alignment.center,
              child: Text('${month.total ?? 0}', style: totalStyle),
            ),
          ],
        );
      }).toList();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branch labels column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                ...branches.map(branchCell),
                Container(
                  height: 28,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Text('Total', style: totalStyle),
                ),
              ],
            ),
            Container(width: 1, color: _dividerColor),
            const SizedBox(width: 12),
            // Last 7 Days
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeader('Last 7 Days', const Color(0xFF2196F3)),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: buildDayColumns()),
              ],
            ),
            const SizedBox(width: 24),
            Container(width: 1, color: _dividerColor),
            const SizedBox(width: 12),
            // Last 3 Months
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeader('Last 3 Months', const Color(0xFFDF6E98)),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: buildMonthColumns()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
