import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/doctor/doctor_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart';
import 'package:klinik_aurora_portal/models/doctor/update_doctor_request.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/no_records/no_records.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/table/table_header_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class DoctorList extends StatefulWidget {
  final Data? branch;
  const DoctorList({super.key, required this.branch});

  @override
  State<DoctorList> createState() => _DoctorListState();
}

class _DoctorListState extends State<DoctorList> {
  List<TableHeaderAttribute> headers = [
    TableHeaderAttribute(attribute: 'doctorName', label: 'Doctor Name', allowSorting: false, columnSize: ColumnSize.S),
    TableHeaderAttribute(attribute: 'doctorPhone', label: 'Contact No.', allowSorting: false, columnSize: ColumnSize.S),
    TableHeaderAttribute(
      attribute: 'status',
      label: 'Status',
      allowSorting: false,
      columnSize: ColumnSize.S,
      width: 100,
    ),
    TableHeaderAttribute(
      attribute: 'createdDate',
      label: 'Created Date',
      allowSorting: false,
      columnSize: ColumnSize.S,
      width: 150,
    ),
    TableHeaderAttribute(
      attribute: 'actions',
      label: 'Actions',
      allowSorting: false,
      columnSize: ColumnSize.S,
      width: 70,
    ),
  ];
  @override
  void initState() {
    DoctorController.get(context, 1, 10000, branchId: widget.branch?.branchId).then((value) {
      if (responseCode(value.code)) {
        context.read<DoctorController>().doctorBranchResponse = value.data;
      } else {
        showDialogError(context, value.data?.message ?? 'error'.tr(gender: 'generic'));
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<DoctorController>(
                builder: (context, snapshot, _) {
                  return CardContainer(
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding / 2),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSelectableText(
                                  '${widget.branch?.branchName} Person(s) in Charge',
                                  style: AppTypography.displayMedium(context).apply(color: primary),
                                ),
                                AppPadding.vertical(),
                                SizedBox(
                                  width: screenWidth1728(50),
                                  height: screenHeight829(55),
                                  child:
                                      (snapshot.doctorBranchResponse != null &&
                                              snapshot.doctorBranchResponse!.data!.isEmpty)
                                          ? const NoRecordsWidget()
                                          : DataTable2(
                                            columnSpacing: 12,
                                            horizontalMargin: 12,
                                            minWidth: screenWidth1728(50),
                                            isHorizontalScrollBarVisible: true,
                                            isVerticalScrollBarVisible: true,
                                            columns: columns(),
                                            headingRowColor: WidgetStateProperty.all(Colors.white),
                                            headingRowHeight: 51,
                                            decoration: const BoxDecoration(),
                                            border: TableBorder(
                                              left: BorderSide(
                                                width: 1,
                                                color: Colors.black.withAlpha(opacityCalculation(.1)),
                                              ),
                                              top: BorderSide(
                                                width: 1,
                                                color: Colors.black.withAlpha(opacityCalculation(.1)),
                                              ),
                                              bottom: BorderSide(
                                                width: 1,
                                                color: Colors.black.withAlpha(opacityCalculation(.1)),
                                              ),
                                              right: BorderSide(
                                                width: 1,
                                                color: Colors.black.withAlpha(opacityCalculation(.1)),
                                              ),
                                              verticalInside: BorderSide(
                                                width: 1,
                                                color: Colors.black.withAlpha(opacityCalculation(.1)),
                                              ),
                                            ),
                                            rows: [
                                              for (
                                                int index = 0;
                                                index < (snapshot.doctorBranchResponse?.data?.length ?? 0);
                                                index++
                                              )
                                                DataRow(
                                                  color: WidgetStateProperty.all(
                                                    index % 2 == 1 ? Colors.white : const Color(0xFFF3F2F7),
                                                  ),
                                                  cells: [
                                                    DataCell(
                                                      AppSelectableText(
                                                        snapshot.doctorBranchResponse?.data?[index].doctorName ?? 'N/A',
                                                      ),
                                                    ),
                                                    DataCell(
                                                      AppSelectableText(
                                                        snapshot.doctorBranchResponse?.data?[index].doctorPhone ??
                                                            'N/A',
                                                      ),
                                                    ),
                                                    DataCell(
                                                      AppSelectableText(
                                                        snapshot.doctorBranchResponse?.data?[index].doctorStatus == 1
                                                            ? 'Active'
                                                            : 'Inactive',
                                                        style: AppTypography.bodyMedium(context).apply(
                                                          color: statusColor(
                                                            snapshot.doctorBranchResponse?.data?[index].doctorStatus ==
                                                                    1
                                                                ? 'active'
                                                                : 'inactive',
                                                          ),
                                                          fontWeightDelta: 1,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      AppSelectableText(
                                                        dateConverter(
                                                              snapshot.doctorBranchResponse?.data?[index].createdDate,
                                                            ) ??
                                                            'N/A',
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          IconButton(
                                                            onPressed: () async {
                                                              try {
                                                                if (await showConfirmDialog(
                                                                  context,
                                                                  snapshot
                                                                              .doctorBranchResponse
                                                                              ?.data?[index]
                                                                              .doctorStatus ==
                                                                          1
                                                                      ? 'Are you certain you wish to deactivate this PIC account? Please note, this action can be reversed at a later time.'
                                                                      : 'Are you certain you wish to activate this PIC account? Please note, this action can be reversed at a later time.',
                                                                )) {
                                                                  Future.delayed(Duration.zero, () {
                                                                    DoctorController.update(
                                                                      context,
                                                                      UpdateDoctorRequest(
                                                                        doctorId:
                                                                            snapshot
                                                                                .doctorBranchResponse
                                                                                ?.data?[index]
                                                                                .doctorId,
                                                                        branchId:
                                                                            snapshot
                                                                                .doctorBranchResponse
                                                                                ?.data?[index]
                                                                                .branchId,
                                                                        doctorPhone:
                                                                            snapshot
                                                                                .doctorBranchResponse
                                                                                ?.data?[index]
                                                                                .doctorPhone,
                                                                        doctorName:
                                                                            snapshot
                                                                                .doctorBranchResponse
                                                                                ?.data?[index]
                                                                                .doctorName,
                                                                        doctorStatus:
                                                                            snapshot
                                                                                        .doctorBranchResponse
                                                                                        ?.data?[index]
                                                                                        .doctorStatus ==
                                                                                    1
                                                                                ? 0
                                                                                : 1,
                                                                      ),
                                                                    ).then((value) {
                                                                      if (responseCode(value.code)) {
                                                                        DoctorController.get(
                                                                          context,
                                                                          1,
                                                                          pageSize,
                                                                          branchId:
                                                                              snapshot
                                                                                  .doctorBranchResponse
                                                                                  ?.data?[index]
                                                                                  .branchId,
                                                                        ).then((value) {
                                                                          dismissLoading();
                                                                          if (responseCode(value.code)) {
                                                                            context
                                                                                .read<DoctorController>()
                                                                                .doctorBranchResponse = value.data;
                                                                            showDialogSuccess(
                                                                              context,
                                                                              'Successfully updated new PIC',
                                                                            );
                                                                          } else {
                                                                            showDialogSuccess(
                                                                              context,
                                                                              'Successfully updated new PIC',
                                                                            );
                                                                          }
                                                                        });
                                                                      } else {
                                                                        showDialogError(
                                                                          context,
                                                                          value.data?.message ??
                                                                              'ERROR : ${value.code}',
                                                                        );
                                                                      }
                                                                    });
                                                                  });
                                                                }
                                                              } catch (e) {
                                                                debugPrint(e.toString());
                                                              }
                                                            },
                                                            icon: Icon(
                                                              snapshot
                                                                          .doctorBranchResponse
                                                                          ?.data?[index]
                                                                          .doctorStatus ==
                                                                      1
                                                                  ? Icons.delete
                                                                  : Icons.play_arrow,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Positioned(
                        //   top: 10,
                        //   right: 10,
                        //   child: Container(
                        //     decoration: const BoxDecoration(
                        //       shape: BoxShape.circle,
                        //       color: secondaryColor,
                        //     ),
                        //     child: IconButton(
                        //       onPressed: () {

                        //       },
                        //       icon: const Icon(Icons.add),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<DataColumn2> columns() {
    return [
      for (TableHeaderAttribute item in headers)
        DataColumn2(
          fixedWidth: item.width,
          label: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AppSelectableText(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium?.apply(fontWeightDelta: 2),
                      ),
                    ),
                    // if (item.tooltip != null) ...[
                    //   const SizedBox(
                    //     width: 10,
                    //   ),
                    //   const Icon(
                    //     Icons.help_outline_rounded,
                    //     size: 18,
                    //     color: Colors.grey,
                    //   ),
                    // ],
                  ],
                ),
              ),
            ],
          ),
          numeric: item.numeric,
          tooltip: item.tooltip,
          size: item.columnSize ?? ColumnSize.M,
        ),
    ];
  }
}
