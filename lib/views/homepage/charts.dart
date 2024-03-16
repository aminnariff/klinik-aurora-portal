import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/charts/line_chart_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class LineChartWidget extends StatelessWidget {
  final LineChartAttribute attribute;

  const LineChartWidget({super.key, required this.attribute});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attribute.label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSelectableText(
                attribute.label!,
                style: AppTypography.bodyLarge(context).apply(color: attribute.darkMode ? Colors.white : null),
              ),
              legends(
                attribute.legends,
              )
            ],
          ),
          AppPadding.vertical(),
        ],
        Expanded(
          child: LineChart(
            sampleData1,
            duration: const Duration(milliseconds: 150),
          ),
        ),
      ],
    );
  }

  LineChartData get sampleData1 => LineChartData(
        lineTouchData: lineTouchData,
        gridData: gridData,
        titlesData: titlesData,
        borderData: borderData,
        lineBarsData: lineBarsData,
        minX: 0,
        maxX: 14,
        maxY: attribute.maxY?.toDouble(),
        minY: 0,
      );

  LineTouchData get lineTouchData => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
        ),
      );

  FlTitlesData get titlesData => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: bottomTitles,
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: leftTitles(),
        ),
      );

  List<LineChartBarData> get lineBarsData => [
        for (int index = 0; index < attribute.items.length; index++) lineChartBarData(index),
      ];

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    TextStyle style = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 14,
      color: attribute.darkMode ? Colors.white : textPrimaryColor,
    );

    double maxY = attribute.maxY?.toDouble() ?? 20.0;
    int maxTitles = 6;
    int interval = (maxY / (maxTitles - 1)).ceil();

    if (value % interval == 0) {
      return Text(value.toInt().toString(), style: style, textAlign: TextAlign.center);
    } else {
      return Container();
    }
  }

  SideTitles leftTitles() => SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true,
        interval: 1,
        reservedSize: 40,
      );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    TextStyle style = TextStyle(
        fontSize: 15.0, fontWeight: FontWeight.w500, color: attribute.darkMode ? Colors.white : textPrimaryColor);

    if (attribute.labels.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(attribute.labels[value.toInt()], style: style),
      );
    } else {
      return const SizedBox();
    }
  }

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  FlGridData get gridData => const FlGridData(show: false);

  FlBorderData get borderData => FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: primary.withOpacity(0.2), width: 4),
          left: const BorderSide(color: Colors.transparent),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      );

  LineChartBarData lineChartBarData(int line) {
    return LineChartBarData(
      isCurved: true,
      color: lineColor(line),
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: line == 0
          ? BarAreaData(show: false)
          : BarAreaData(
              show: false,
              color: Colors.redAccent.withOpacity(0),
            ),
      spots: [
        for (int index = 0; index < attribute.items[line].length; index++)
          FlSpot(index.toDouble(), attribute.items[line][index].value!),
      ],
    );
  }

  Color lineColor(int index, {String? item}) {
    switch (item ?? attribute.items[index][0].type) {
      case 'NEW':
        return attribute.darkMode ? contentColorCyan : statusColor('NEW');
      case 'OPEN':
        return attribute.darkMode ? contentColorYellow : statusColor('OPEN');
      case 'IN_PROGRESS':
        return statusColor('IN_PROGRESS');
      case 'COMPLETE':
        return attribute.darkMode ? contentColorGreen : statusColor('COMPLETE');
      case 'RESOLVED':
        return attribute.darkMode ? contentColorGreen : statusColor('RESOLVED');
      default:
        return const Color(0XFF52B3E0);
    }
  }

  Widget legends(List<String> items) {
    return Row(
      children: [
        for (int index = 0; index < items.length; index++) ...[
          Container(
            color: lineColor(
              index,
              item: items[index],
            ),
            height: 15,
            width: 15,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          AppSelectableText(
            items[index],
            style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w500,
                color: attribute.darkMode ? Colors.white : textPrimaryColor),
          ),
        ],
      ],
    );
  }
}
