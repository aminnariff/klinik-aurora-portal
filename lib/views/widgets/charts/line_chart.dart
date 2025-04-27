import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/charts/line_chart_attribute.dart';

class LineChartWidget extends StatelessWidget {
  final LineChartAttribute attribute;

  const LineChartWidget({super.key, required this.attribute});

  @override
  Widget build(BuildContext context) {
    return LineChart(sampleData1, duration: const Duration(milliseconds: 250));
  }

  LineChartData get sampleData1 => LineChartData(
    lineTouchData: lineTouchData1,
    gridData: gridData,
    titlesData: titlesData1,
    borderData: borderData,
    lineBarsData: lineBarsData1,
    minX: 0,
    maxX: 15,
    maxY: 4,
    minY: 0,
  );

  LineTouchData get lineTouchData1 =>
      LineTouchData(handleBuiltInTouches: true, touchTooltipData: LineTouchTooltipData());

  FlTitlesData get titlesData1 => FlTitlesData(
    bottomTitles: AxisTitles(sideTitles: bottomTitles),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(sideTitles: leftTitles()),
  );

  List<LineChartBarData> get lineBarsData1 => [lineChartBarData1_1, lineChartBarData1_2];

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
    String text;
    switch (value.toInt()) {
      case 1:
        text = '1m';
        break;
      case 2:
        text = '2m';
        break;
      case 3:
        text = '3m';
        break;
      case 4:
        text = '5m';
        break;
      case 5:
        text = '6m';
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.center);
  }

  SideTitles leftTitles() =>
      SideTitles(getTitlesWidget: leftTitleWidgets, showTitles: true, interval: 1, reservedSize: 40);

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
    Widget text;
    switch (value.toInt()) {
      case 1:
        text = const Text('1/10', style: style);
        break;
      case 2:
        text = const Text('2/10', style: style);
        break;
      case 3:
        text = const Text('3/10', style: style);
        break;
      case 7:
        text = const Text('OCT', style: style);
        break;
      case 12:
        text = const Text('DEC', style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(meta: meta, space: 10, child: text);
  }

  SideTitles get bottomTitles =>
      SideTitles(showTitles: true, reservedSize: 32, interval: 1, getTitlesWidget: bottomTitleWidgets);

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

  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
    isCurved: true,
    color: Colors.cyan,
    barWidth: 5,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
    spots: const [
      FlSpot(1, 1),
      FlSpot(2, 1.5),
      FlSpot(3, 1.5),
      FlSpot(4, 1.5),
      FlSpot(5, 1.4),
      FlSpot(6, 3.4),
      FlSpot(7, 3.4),
      FlSpot(8, 3.4),
      FlSpot(9, 3.4),
      FlSpot(10, 2),
      FlSpot(11, 2),
      FlSpot(12, 2.2),
      FlSpot(13, 1.8),
      FlSpot(14, 1.8),
      FlSpot(15, 1.8),
    ],
  );

  LineChartBarData get lineChartBarData1_2 => LineChartBarData(
    isCurved: true,
    color: Colors.blue,
    barWidth: 5,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false, color: Colors.blue.withOpacity(0)),
    spots: const [
      FlSpot(1, 1),
      FlSpot(2, 2.8),
      FlSpot(3, 2.8),
      FlSpot(4, 2.8),
      FlSpot(5, 2.8),
      FlSpot(6, 2.8),
      FlSpot(7, 1.2),
      FlSpot(8, 1.2),
      FlSpot(9, 1.2),
      FlSpot(10, 2.8),
      FlSpot(11, 2.6),
      FlSpot(12, 2.6),
      FlSpot(13, 3.9),
      FlSpot(14, 3.9),
      FlSpot(15, 3.9),
    ],
  );
}
