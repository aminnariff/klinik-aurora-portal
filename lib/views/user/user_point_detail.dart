import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/point_management/point_management_controller.dart';
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/views/points/point_detail.dart';
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

class UserPointDetail extends StatefulWidget {
  final UserResponse user;
  const UserPointDetail({super.key, required this.user});

  @override
  State<UserPointDetail> createState() => _UserPointDetailState();
}

class _UserPointDetailState extends State<UserPointDetail> {
  List<TableHeaderAttribute> headers = [
    TableHeaderAttribute(
      attribute: 'transactionId',
      label: 'Transaction ID',
      allowSorting: false,
      columnSize: ColumnSize.S,
    ),
    TableHeaderAttribute(
      attribute: 'voucherName',
      label: 'Voucher Name',
      allowSorting: false,
      columnSize: ColumnSize.S,
    ),
    TableHeaderAttribute(
      attribute: 'points',
      label: 'Points',
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
  ];
  @override
  void initState() {
    PointManagementController.get(context, 1, userId: widget.user.userId).then((value) {
      if (responseCode(value.code)) {
        context.read<PointManagementController>().userPointsResponse = value.data;
      } else {
        showDialogError(context, value.message ?? value.data?.message ?? 'error'.tr(gender: 'generic'));
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
              Consumer<PointManagementController>(
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
                                  '${widget.user.userFullname}\'s Points',
                                  style: AppTypography.displayMedium(context).apply(color: primary),
                                ),
                                AppPadding.vertical(),
                                SizedBox(
                                  width: screenWidth1728(50),
                                  height: screenHeight829(55),
                                  child:
                                      (snapshot.userPointsResponse != null &&
                                          snapshot.userPointsResponse!.data!.isEmpty)
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
                                              index < (snapshot.userPointsResponse?.data?.length ?? 0);
                                              index++
                                            )
                                              DataRow(
                                                color: WidgetStateProperty.all(
                                                  index % 2 == 1 ? Colors.white : const Color(0xFFF3F2F7),
                                                ),
                                                cells: [
                                                  DataCell(
                                                    AppSelectableText(
                                                      snapshot.userPointsResponse?.data?[index].transactionId ?? 'N/A',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    AppSelectableText(
                                                      snapshot.userPointsResponse?.data?[index].voucherName ?? 'N/A',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    AppSelectableText(
                                                      snapshot.userPointsResponse?.data?[index].totalPoint.toString() ??
                                                          'N/A',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    AppSelectableText(
                                                      dateConverter(
                                                            snapshot.userPointsResponse?.data?[index].createdDate,
                                                          ) ??
                                                          'N/A',
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
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: secondaryColor),
                            child: IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return PointDetail(user: widget.user);
                                  },
                                );
                              },
                              icon: const Icon(Icons.add),
                            ),
                          ),
                        ),
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
