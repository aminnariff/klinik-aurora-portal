import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/dashboard_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/dashboard_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class GraphWidget extends StatefulWidget {
  const GraphWidget({super.key});

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  List<Color> gradientColors = [const Color(0xff23b6e6), const Color(0xff02d39a)];

  List<int> totalRegistrations = [];
  bool showAvg = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 4.5,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              color: Color(0xff232d37),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                right: screenPadding * 1.5,
                left: screenPadding * 1.5,
                top: screenPadding * 1.5,
                bottom: 12,
              ),
              child: Consumer<DashboardController>(
                builder: (context, snapshot, _) {
                  return LineChart(showAvg ? avgData() : mainData(snapshot.dashboardResponse?.data));
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(screenPadding, screenPadding / 2, 0, 0),
          child: Text(
            'Registrations in the Past 7 Months',
            style: AppTypography.displayMedium(context).apply(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(color: Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 16);
    Widget text;
    Data? response = context.read<DashboardController>().dashboardResponse?.data;
    switch (value.toInt()) {
      case 0:
        text =
            response == null
                ? const SizedBox()
                : Text(
                  convertToMonthYear(
                    response.totalRegistrationByMonth?[0].month ?? 0,
                    response.totalRegistrationByMonth?[0].year ?? 0,
                  ),
                  style: style,
                );
        break;
      case 1:
        text =
            response == null
                ? const SizedBox()
                : Text(
                  convertToMonthYear(
                    response.totalRegistrationByMonth?[1].month ?? 0,
                    response.totalRegistrationByMonth?[1].year ?? 0,
                  ),
                  style: style,
                );
        break;
      case 2:
        text =
            response == null
                ? const SizedBox()
                : Text(
                  convertToMonthYear(
                    response.totalRegistrationByMonth?[2].month ?? 0,
                    response.totalRegistrationByMonth?[2].year ?? 0,
                  ),
                  style: style,
                );
      case 3:
        text =
            response == null
                ? const SizedBox()
                : Text(
                  convertToMonthYear(
                    response.totalRegistrationByMonth?[3].month ?? 0,
                    response.totalRegistrationByMonth?[3].year ?? 0,
                  ),
                  style: style,
                );
      case 4:
        text =
            response == null
                ? const SizedBox()
                : Text(
                  convertToMonthYear(
                    response.totalRegistrationByMonth?[4].month ?? 0,
                    response.totalRegistrationByMonth?[4].year ?? 0,
                  ),
                  style: style,
                );
      case 5:
        text =
            response == null
                ? const SizedBox()
                : Text(
                  convertToMonthYear(
                    response.totalRegistrationByMonth?[5].month ?? 0,
                    response.totalRegistrationByMonth?[5].year ?? 0,
                  ),
                  style: style,
                );
      case 6:
        text =
            response == null
                ? const SizedBox()
                : Text(
                  convertToMonthYear(
                    response.totalRegistrationByMonth?[6].month ?? 0,
                    response.totalRegistrationByMonth?[6].year ?? 0,
                  ),
                  style: style,
                );
      default:
        text = const Text('', style: style);
        break;
    }

    return SideTitleWidget(meta: meta, child: text);
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(color: Color(0xff67727d), fontWeight: FontWeight.bold, fontSize: 15);
    String text;
    switch (value.toInt()) {
      case 1:
        text = '${getYAxisLabelsWithGap(totalRegistrations)[0]}';
        break;
      case 2:
        text = '${getYAxisLabelsWithGap(totalRegistrations)[1]}';
        break;
      case 3:
        text = '${getYAxisLabelsWithGap(totalRegistrations)[2]}';
        break;
      case 4:
        text = '${getYAxisLabelsWithGap(totalRegistrations)[3]}';
        break;
      case 5:
        text = '${getYAxisLabelsWithGap(totalRegistrations)[4]}';
        break;
      case 6:
        text = '${getYAxisLabelsWithGap(totalRegistrations)[5]}';
        break;
      case 7:
        text = '${getYAxisLabelsWithGap(totalRegistrations)[6]}';
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.left);
  }

  List<int> getYAxisLabelsWithGap(List<int> data) {
    if (data.isEmpty) {
      return [0, 0, 0, 0, 0, 0, 0];
    }
    data.sort();
    int min = data.first;
    int max = data.last;
    int median = data[data.length ~/ 2];

    // Adjust values to create a gap for better visualization
    int adjustedMin = (min * 0.8).floor(); // Example: 20% less
    int adjustedMax = (max * 1.5).ceil(); // Example: 50% more

    if (adjustedMin < 0) {
      adjustedMin = 0;
    }

    return [adjustedMin, median, adjustedMax, max + 10];
  }

  LineChartData mainData(Data? response) {
    // double first = response?.totalRegistrationByMonth?[0].totalRegistrationByMonth?.toDouble() ?? 0;
    // double second = response?.totalRegistrationByMonth?[1].totalRegistrationByMonth?.toDouble() ?? 0;
    // double third = response?.totalRegistrationByMonth?[2].totalRegistrationByMonth?.toDouble() ?? 0;
    // double forth = response?.totalRegistrationByMonth?[3].totalRegistrationByMonth?.toDouble() ?? 0;
    // double fifth = response?.totalRegistrationByMonth?[4].totalRegistrationByMonth?.toDouble() ?? 0;
    // double sixth = response?.totalRegistrationByMonth?[5].totalRegistrationByMonth?.toDouble() ?? 0;
    // double seventh = response?.totalRegistrationByMonth?[6].totalRegistrationByMonth?.toDouble() ?? 0;

    for (TotalRegistrationByMonth? element in response?.totalRegistrationByMonth ?? []) {
      totalRegistrations.add(element?.totalRegistrationByMonth ?? 0);
    }
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(color: Color(0xff37434d), strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(color: Color(0xff37434d), strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: bottomTitleWidgets),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false, interval: 1, getTitlesWidget: leftTitleWidgets, reservedSize: 42),
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d))),
      minX: 0,
      maxX: ((response?.totalRegistrationByMonth?.length.toDouble()) ?? 0) - 1,
      minY: 0,
      maxY: getYAxisLabelsWithGap(totalRegistrations)[3].toDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (int index = 0; index < (response?.totalRegistrationByMonth?.length ?? 0); index++)
              FlSpot(
                index.toDouble(),
                response?.totalRegistrationByMonth?[index].totalRegistrationByMonth?.toDouble() ?? 0,
              ),
            // FlSpot(0, first),
            // FlSpot(1, second),
            // FlSpot(2, third),
            // FlSpot(3, forth),
            // FlSpot(4, fifth),
            // FlSpot(5, sixth),
            // FlSpot(6, seventh),
          ],
          isCurved: true,
          gradient: LinearGradient(colors: gradientColors),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors.map((color) => color.withAlpha(opacityCalculation(.3))).toList(),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData avgData() {
    return LineChartData(
      lineTouchData: const LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        verticalInterval: 1,
        horizontalInterval: 1,
        getDrawingVerticalLine: (value) {
          return const FlLine(color: Color(0xff37434d), strokeWidth: 1);
        },
        getDrawingHorizontalLine: (value) {
          return const FlLine(color: Color(0xff37434d), strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: bottomTitleWidgets, interval: 1),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false, getTitlesWidget: leftTitleWidgets, reservedSize: 42, interval: 1),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d))),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 3.44),
            FlSpot(2.6, 3.44),
            FlSpot(4.9, 3.44),
            FlSpot(6.8, 3.44),
            FlSpot(8, 3.44),
            FlSpot(9.5, 3.44),
            FlSpot(11, 3.44),
          ],
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              ColorTween(begin: gradientColors[0], end: gradientColors[1]).lerp(0.2)!,
              ColorTween(begin: gradientColors[0], end: gradientColors[1]).lerp(0.2)!,
            ],
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                ColorTween(
                  begin: gradientColors[0],
                  end: gradientColors[1],
                ).lerp(0.2)!.withAlpha(opacityCalculation(.1)),
                ColorTween(
                  begin: gradientColors[0],
                  end: gradientColors[1],
                ).lerp(0.2)!.withAlpha(opacityCalculation(.1)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
