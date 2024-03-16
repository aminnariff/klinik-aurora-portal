// import 'package:flutter/material.dart';
// import 'package:klinik_aurora_portal/config/color.dart';
// import 'package:klinik_aurora_portal/config/loading.dart';
// import 'package:klinik_aurora_portal/controllers/api_controller.dart';
// import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
// import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
// import 'package:klinik_aurora_portal/controllers/metric/metric_controller.dart';
// import 'package:klinik_aurora_portal/controllers/order/order_statistic_controller.dart' as order_controller;
// import 'package:klinik_aurora_portal/controllers/service/service_request_statistic_controller.dart'
//     as service_request_controller;
// import 'package:klinik_aurora_portal/controllers/task/task_statistic_controller.dart' as task_controller;
// import 'package:klinik_aurora_portal/models/metric/metric_response.dart';
// import 'package:klinik_aurora_portal/views/homepage/charts.dart';
// import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
// import 'package:klinik_aurora_portal/views/widgets/charts/line_chart_attribute.dart';
// import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
// import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
// import 'package:klinik_aurora_portal/views/widgets/size.dart';
// import 'package:klinik_aurora_portal/views/widgets/switch/switch.dart';
// import 'package:klinik_aurora_portal/views/widgets/tooltip/app_tooltip.dart';
// import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
// import 'package:provider/provider.dart';

// class Dashboard extends StatefulWidget {
//   const Dashboard({super.key});

//   @override
//   State<Dashboard> createState() => _DashboardState();
// }

// class _DashboardState extends State<Dashboard> {
//   @override
//   void initState() {
//     showLoading();
//     task_controller.TaskStatisticController.get(context).then((value) {
//       if (responseCode(value.code)) {
//         context.read<task_controller.TaskStatisticController>().taskStatistic = value.data;
//       }
//     });
//     service_request_controller.ServiceRequestStatisticController.get(context).then((value) {
//       if (responseCode(value.code)) {
//         context.read<service_request_controller.ServiceRequestStatisticController>().serviceRequestStatistic =
//             value.data;
//       }
//     });
//     order_controller.OrderStatisticController.get(context).then((value) {
//       if (responseCode(value.code)) {
//         context.read<order_controller.OrderStatisticController>().orderStatistic = value.data;
//       }
//     });
//     sequentialMetricLoop();
//     super.initState();
//   }

//   Future<ApiResponse<MetricResponse>> delayTask(int index) async {
//     return MetricController.get(context, context.read<MetricController>().metricList[index]).then((value) {
//       return value;
//     });
//   }

//   Future<void> sequentialMetricLoop() async {
//     List<MetricResponse?> temp = [];
//     for (int index = 0; index < context.read<MetricController>().metricList.length; index++) {
//       Future.delayed(Duration.zero, () async {
//         await delayTask(index).then((value) {
//           if (responseCode(value.code)) {
//             temp.add(value.data);
//           }
//           if (temp.length == context.read<MetricController>().metricList.length) {
//             context.read<MetricController>().metricResponse = temp;
//             dismissLoading();
//           }
//         });
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           IntrinsicHeight(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Expanded(
//                   flex: 3,
//                   child: Consumer<DarkModeController>(
//                     builder: (context, darkController, child) {
//                       return Column(
//                         children: [
//                           Container(
//                             margin: EdgeInsets.fromLTRB(screenPadding, screenPadding, screenPadding, 0),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 const AppSelectableText(
//                                   'Charts Dark Mode :',
//                                 ),
//                                 Consumer<DarkModeController>(
//                                   builder: (context, snapshot, child) {
//                                     return AppCupertinoSwitch(
//                                       value: snapshot.darkMode,
//                                       onChanged: (bool value) {
//                                         snapshot.darkMode = value;
//                                       },
//                                     );
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ),
//                           SizedBox(
//                             height: 300,
//                             child: CardContainer(
//                               Padding(
//                                 padding:
//                                     EdgeInsets.fromLTRB(screenPadding, screenPadding / 2, screenPadding, screenPadding),
//                                 child: Consumer<order_controller.OrderStatisticController>(
//                                   builder: (context, snapshot, _) {
//                                     return LineChartWidget(
//                                       attribute: LineChartAttribute(
//                                           items: snapshot.lines ?? [],
//                                           labels: snapshot.labels ?? [],
//                                           maxY: snapshot.maxY,
//                                           label: 'Order',
//                                           darkMode: darkController.darkMode,
//                                           legends: ['IN_PROGRESS', 'COMPLETE']),
//                                     );
//                                   },
//                                 ),
//                               ),
//                               color: darkController.darkMode ? darkModeCardColor : null,
//                               margin: EdgeInsets.fromLTRB(screenPadding, screenPadding / 2, screenPadding, 0),
//                             ),
//                           ),
//                           SizedBox(
//                             height: 300,
//                             child: CardContainer(
//                               Padding(
//                                 padding:
//                                     EdgeInsets.fromLTRB(screenPadding, screenPadding / 2, screenPadding, screenPadding),
//                                 child: Consumer<task_controller.TaskStatisticController>(
//                                   builder: (context, snapshot, _) {
//                                     return LineChartWidget(
//                                       attribute: LineChartAttribute(
//                                         items: snapshot.lines ?? [],
//                                         labels: snapshot.labels ?? [],
//                                         maxY: snapshot.maxY,
//                                         label: 'Tasks',
//                                         darkMode: darkController.darkMode,
//                                         legends: ['OPEN', 'RESOLVED'],
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                               color: darkController.darkMode ? darkModeCardColor : null,
//                               margin: EdgeInsets.fromLTRB(screenPadding, screenPadding / 2, screenPadding, 0),
//                             ),
//                           ),
//                           SizedBox(
//                             height: 300,
//                             child: CardContainer(
//                               Padding(
//                                 padding:
//                                     EdgeInsets.fromLTRB(screenPadding, screenPadding / 2, screenPadding, screenPadding),
//                                 child: Consumer<service_request_controller.ServiceRequestStatisticController>(
//                                   builder: (context, snapshot, _) {
//                                     return LineChartWidget(
//                                       attribute: LineChartAttribute(
//                                         items: snapshot.lines ?? [],
//                                         labels: snapshot.labels ?? [],
//                                         maxY: snapshot.maxY,
//                                         label: 'Service Request',
//                                         darkMode: darkController.darkMode,
//                                         legends: ['NEW', 'IN_PROGRESS', 'COMPLETE'],
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                               color: darkController.darkMode ? darkModeCardColor : null,
//                               margin: EdgeInsets.fromLTRB(screenPadding, screenPadding / 2, screenPadding, 0),
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 ),
//                 Expanded(
//                   flex: 1,
//                   child: CardContainer(
//                     Padding(
//                       padding: EdgeInsets.all(screenPadding / 2),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           AppSelectableText(
//                             'System Metrics',
//                             style: AppTypography.bodyLarge(context),
//                           ),
//                           AppPadding.vertical(denominator: 2),
//                           Consumer<MetricController>(builder: (context, snapshot, _) {
//                             return Column(
//                               children: [
//                                 for (int index = 0; index < (snapshot.metricResponse?.length ?? 0); index++)
//                                   Container(
//                                     color: Colors.white,
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           children: [
//                                             Expanded(
//                                               child: Container(
//                                                 color: disabledColor,
//                                                 padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                                                 child: Row(
//                                                   children: [
//                                                     AppSelectableText(snapshot.metricResponse?[index]?.name ?? ''),
//                                                     AppTooltip(
//                                                       message: snapshot.metricResponse?[index]?.description ?? 'N/A',
//                                                       child: const Icon(
//                                                         Icons.help_outline_rounded,
//                                                         size: 18,
//                                                         color: Colors.grey,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         Padding(
//                                           padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                                           child: AppSelectableText(
//                                             '${snapshot.metricResponse?[index]?.measurements?[0].value ?? 'No Data'}',
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                               ],
//                             );
//                           }),
//                         ],
//                       ),
//                     ),
//                     margin: EdgeInsets.fromLTRB(0, screenPadding, screenPadding / 2, 0),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           AppPadding.vertical(denominator: 1 / 3),
//         ],
//       ),
//     );
//   }
// }
