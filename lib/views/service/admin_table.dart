// import 'package:flutter/material.dart';
// import 'package:klinik_aurora_portal/config/color.dart';
// import 'package:klinik_aurora_portal/controllers/service/service_controller.dart';
// import 'package:klinik_aurora_portal/views/widgets/no_records/no_records.dart';
// import 'package:provider/provider.dart';

// Widget superadminTable(BuildContext context) {
//     return Consumer<ServiceController>(
//       builder: (context, snapshot, child) {
//         if (snapshot.servicesResponse == null) {
//           return const Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [Expanded(child: Center(child: CircularProgressIndicator(color: secondaryColor)))],
//           );
//         } else {
//           return snapshot.servicesResponse?.data == null || snapshot.servicesResponse!.data!.isEmpty
//               ? Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [tableButton(), const Expanded(child: Center(child: NoRecordsWidget()))],
//               )
//               : Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   tableButton(),
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                       child: Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           Container(
//                             decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white),
//                             padding: const EdgeInsets.all(5),
//                             child: DataTable2(
//                               columnSpacing: 12,
//                               horizontalMargin: 12,
//                               minWidth: 1300,
//                               isHorizontalScrollBarVisible: true,
//                               isVerticalScrollBarVisible: true,
//                               columns: columns(),
//                               headingRowColor: WidgetStateProperty.all(Colors.white),
//                               headingRowHeight: 51,
//                               decoration: const BoxDecoration(),
//                               border: TableBorder(
//                                 left: BorderSide(width: 1, color: Colors.black.withAlpha(opacityCalculation(.1))),
//                                 top: BorderSide(width: 1, color: Colors.black.withAlpha(opacityCalculation(.1))),
//                                 bottom: BorderSide(width: 1, color: Colors.black.withAlpha(opacityCalculation(.1))),
//                                 right: BorderSide(width: 1, color: Colors.black.withAlpha(opacityCalculation(.1))),
//                                 verticalInside: BorderSide(width: 1, color: Colors.black.withAlpha(opacityCalculation(.1))),
//                               ),
//                               rows: [
//                                 for (int index = 0; index < (snapshot.servicesResponse?.data?.length ?? 0); index++)
//                                   DataRow(
//                                     color: WidgetStateProperty.all(
//                                       index % 2 == 1 ? Colors.white : const Color(0xFFF3F2F7),
//                                     ),
//                                     cells: [
//                                       DataCell(
//                                         Text(
//                                           snapshot.servicesResponse?.data?[index].serviceName ?? 'N/A',
//                                           style: AppTypography.bodyMedium(context).apply(),
//                                         ),
//                                       ),
//                                       DataCell(
//                                         AppSelectableText(
//                                           snapshot.servicesResponse?.data?[index].serviceCategory ?? 'N/A',
//                                         ),
//                                       ),
//                                       DataCell(
//                                         AppTooltip(
//                                           message:
//                                               'Booking Fee: RM ${snapshot.servicesResponse?.data?[index].serviceBookingFee}',
//                                           child: Text(
//                                             snapshot.servicesResponse?.data?[index].servicePrice != null
//                                                 ? 'RM ${snapshot.servicesResponse?.data?[index].servicePrice}'
//                                                 : 'N/A',
//                                           ),
//                                         ),
//                                       ),
//                                       DataCell(
//                                         AppSelectableText(
//                                           snapshot.servicesResponse?.data?[index].doctorType == 2
//                                               ? 'Sonographer'
//                                               : 'Doctor',
//                                         ),
//                                       ),
//                                       DataCell(
//                                         AppSelectableText(
//                                           snapshot.servicesResponse?.data?[index].serviceStatus == 1
//                                               ? 'Active'
//                                               : 'Inactive',
//                                           style: AppTypography.bodyMedium(context).apply(
//                                             color: statusColor(
//                                               snapshot.servicesResponse?.data?[index].serviceStatus == 1
//                                                   ? 'active'
//                                                   : 'inactive',
//                                             ),
//                                             fontWeightDelta: 1,
//                                           ),
//                                         ),
//                                       ),
//                                       DataCell(
//                                         AppSelectableText(
//                                           dateConverter(snapshot.servicesResponse?.data?[index].createdDate) ?? 'N/A',
//                                         ),
//                                       ),
//                                       DataCell(
//                                         Row(
//                                           mainAxisAlignment: MainAxisAlignment.center,
//                                           children: [
//                                             PopupMenuButton<String>(
//                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                                               offset: const Offset(8, 35),
//                                               color: Colors.white,
//                                               tooltip: '',
//                                               onSelected:
//                                                   (value) => _handleMenuSelection(
//                                                     value,
//                                                     snapshot.servicesResponse?.data?[index] ?? Data(),
//                                                   ),
//                                               itemBuilder:
//                                                   (BuildContext context) => <PopupMenuEntry<String>>[
//                                                     if (context.read<AuthController>().isSuperAdmin)
//                                                       PopupMenuItem<String>(value: 'update', child: Text('Update')),
//                                                     if (context.read<AuthController>().isSuperAdmin)
//                                                       PopupMenuItem<String>(
//                                                         value: 'updateBranchesStatus',
//                                                         child: Text('Update Branch Service'),
//                                                       ),
//                                                     PopupMenuItem<String>(
//                                                       value: 'enableDisable',
//                                                       child: Text(
//                                                         snapshot.servicesResponse?.data?[index].serviceStatus == 1
//                                                             ? 'Deactivate'
//                                                             : 'Re-Activate',
//                                                       ),
//                                                     ),
//                                                   ],
//                                               child: Row(
//                                                 crossAxisAlignment: CrossAxisAlignment.center,
//                                                 children: [
//                                                   Container(
//                                                     padding: const EdgeInsets.all(4),
//                                                     // decoration: const BoxDecoration(
//                                                     //   color: Colors.white,
//                                                     //   shape: BoxShape.circle,
//                                                     // ),
//                                                     child: Icon(Icons.more_vert, color: Colors.grey),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                               ],
//                             ),
//                           ),
//                           if (isNoRecords.value) const AppSelectableText('No Records Found'),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Expanded(child: pagination()),
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Flexible(
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 if (!isMobile && !isTablet)
//                                   const Flexible(
//                                     child: Text('Items per page: ', overflow: TextOverflow.ellipsis, maxLines: 1),
//                                   ),
//                                 perPage(),
//                               ],
//                             ),
//                           ),
//                           if (!isMobile && !isTablet)
//                             Text(
//                               '${((_page) * _pageSize) - _pageSize + 1} - ${((_page) * _pageSize < _totalCount) ? ((_page) * _pageSize) : _totalCount} of $_totalCount',
//                             ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               );
//         }
//       },
//     );
//   }
