import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/dashboard_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/dashboard_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class RegistrationChart extends StatefulWidget {
  const RegistrationChart({super.key});

  @override
  State<RegistrationChart> createState() => _RegistrationChartState();
}

class _RegistrationChartState extends State<RegistrationChart> {
  bool _showChart = true;
  bool _showDaily = true; // true = 7 days, false = 7 months

  static const _bgColor = Color(0xff232d37);
  static const _dividerColor = Color(0xff37434d);
  static const _mutedColor = Color(0xff68737d);

  static const _dailyGradient = [Color(0xFFDF6E98), Color(0xFF6ad1e3)];
  static const _monthlyGradient = [Color(0xff23b6e6), Color(0xff02d39a)];

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        final data = controller.dashboardResponse?.data;

        return Container(
          decoration: const BoxDecoration(color: _bgColor, borderRadius: BorderRadius.all(Radius.circular(18))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Divider(color: _dividerColor, height: 1),
              Padding(
                padding: EdgeInsets.fromLTRB(screenPadding * 1.5, screenPadding, screenPadding * 1.5, screenPadding),
                child: _showChart ? _buildChart(data) : _buildTable(data),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(screenPadding, screenPadding * 0.75, screenPadding * 0.75, screenPadding * 0.75),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Registrations', style: AppTypography.displayMedium(context).apply(color: Colors.white)),
          Row(children: [if (_showChart) _buildPeriodToggle(), const SizedBox(width: 8), _buildViewToggle()]),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      decoration: BoxDecoration(color: _dividerColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_periodOption('7 Days', true), _periodOption('7 Months', false)],
      ),
    );
  }

  Widget _periodOption(String label, bool isDaily) {
    final selected = _showDaily == isDaily;
    return GestureDetector(
      onTap: () => setState(() => _showDaily = isDaily),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? (isDaily ? const Color(0xFFDF6E98) : const Color(0xff23b6e6)) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _mutedColor,
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(color: _dividerColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_viewOption(Icons.show_chart_rounded, true), _viewOption(Icons.table_chart_outlined, false)],
      ),
    );
  }

  Widget _viewOption(IconData icon, bool isChart) {
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

  Widget _buildChart(Data? data) {
    if (_showDaily) {
      return _buildDailyChart(data);
    } else {
      return _buildMonthlyChart(data);
    }
  }

  Widget _buildDailyChart(Data? data) {
    final items = data?.totalRegistrationByDay ?? [];
    if (items.isEmpty) {
      return _emptyState();
    }

    final values = items.map((e) => e.totalRegistrationByDay ?? 0).toList();
    final maxY = _calcMaxY(values);

    return AspectRatio(
      aspectRatio: isMobile ? 1.8 : 4,
      child: LineChart(
        LineChartData(
          lineTouchData: _lineTouchData(getLabel: (spot) => '${spot.y.toInt()} registrations'),
          gridData: _gridData(),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= items.length) return const SizedBox();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      convertToDayMonth(items[index].date ?? ''),
                      style: const TextStyle(color: _mutedColor, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: _dividerColor)),
          minX: 0,
          maxX: (items.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [_lineBar(values, _dailyGradient)],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(Data? data) {
    final items = data?.totalRegistrationByMonth ?? [];
    if (items.isEmpty) {
      return _emptyState();
    }

    final values = items.map((e) => e.totalRegistrationByMonth ?? 0).toList();
    final maxY = _calcMaxY(values);

    return AspectRatio(
      aspectRatio: isMobile ? 1.8 : 4,
      child: LineChart(
        LineChartData(
          lineTouchData: _lineTouchData(getLabel: (spot) => '${spot.y.toInt()} registrations'),
          gridData: _gridData(),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= items.length) return const SizedBox();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      convertToMonthYear(items[index].month ?? 0, items[index].year ?? 0),
                      style: const TextStyle(color: _mutedColor, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: _dividerColor)),
          minX: 0,
          maxX: (items.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [_lineBar(values, _monthlyGradient)],
        ),
      ),
    );
  }

  LineTouchData _lineTouchData({required String Function(LineBarSpot) getLabel}) {
    return LineTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => Colors.blueGrey.withAlpha(opacityCalculation(.85)),
        getTooltipItems: (spots) => spots.map((spot) {
          return LineTooltipItem(
            getLabel(spot),
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          );
        }).toList(),
      ),
    );
  }

  FlGridData _gridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) => const FlLine(color: _dividerColor, strokeWidth: 1),
    );
  }

  LineChartBarData _lineBar(List<int> values, List<Color> colors) {
    return LineChartBarData(
      spots: [for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i].toDouble())],
      isCurved: true,
      gradient: LinearGradient(colors: colors),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.first.withAlpha(opacityCalculation(.3)), colors.last.withAlpha(opacityCalculation(.0))],
        ),
      ),
    );
  }

  double _calcMaxY(List<int> values) {
    if (values.isEmpty) return 10;
    final max = values.reduce((a, b) => a > b ? a : b);
    return max == 0 ? 10 : max * 1.4;
  }

  Widget _buildTable(Data? data) {
    final days = data?.totalRegistrationByDay ?? [];
    final months = data?.totalRegistrationByMonth ?? [];

    if (days.isEmpty && months.isEmpty) return _emptyState();

    const headerStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11);
    const cellStyle = TextStyle(color: _mutedColor, fontSize: 12);
    const valueStyle = TextStyle(color: Colors.white, fontSize: 12);

    Widget sectionHeader(String label, Color color) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }

    Widget colHeader(String text) {
      return Container(
        width: 56,
        height: 24,
        alignment: Alignment.center,
        child: Text(text, textAlign: TextAlign.center, style: headerStyle.copyWith(fontSize: 10)),
      );
    }

    Widget colValue(String text) {
      return Container(
        width: 56,
        height: 26,
        alignment: Alignment.center,
        child: Text(text, style: valueStyle),
      );
    }

    // build daily columns
    final dayColumns = days.map((d) {
      return Column(
        children: [colHeader(convertToDayMonth(d.date ?? '')), colValue('${d.totalRegistrationByDay ?? 0}')],
      );
    }).toList();

    // build monthly columns
    final monthColumns = months.map((m) {
      return Column(
        children: [
          colHeader(convertToMonthYear(m.month ?? 0, m.year ?? 0)),
          colValue('${m.totalRegistrationByMonth ?? 0}'),
        ],
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const Opacity(
                opacity: 0,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('X', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              Container(
                height: 26,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(right: 16),
                child: const Text(
                  'Date',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 26,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Text('Total', style: cellStyle),
                  ),
                ],
              ),
            ],
          ),
          Container(width: 1, color: _dividerColor),
          const SizedBox(width: 12),
          // 7 days
          if (days.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeader('Last 7 Days', const Color(0xFFDF6E98)),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: dayColumns),
              ],
            ),
          if (days.isNotEmpty && months.isNotEmpty) ...[
            const SizedBox(width: 24),
            Container(width: 1, color: _dividerColor),
            const SizedBox(width: 12),
          ],
          // 7 months
          if (months.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeader('Last 7 Months', const Color(0xff23b6e6)),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: monthColumns),
              ],
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Text('No data available', style: TextStyle(color: _mutedColor)),
      ),
    );
  }
}
