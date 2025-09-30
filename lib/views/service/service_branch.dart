import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/models/service_branch/service_branch_response.dart' as service_branch_model;
import 'package:klinik_aurora_portal/models/service_branch/update_service_branch_request.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/multi_time_calendar.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class ServiceBranch extends StatefulWidget {
  final service_branch_model.ServiceBranchResponse? serviceBranch;
  const ServiceBranch({super.key, required this.serviceBranch});

  @override
  State<ServiceBranch> createState() => _ServiceBranchState();
}

class _ServiceBranchState extends State<ServiceBranch> {
  StreamController<DateTime> rebuild = StreamController.broadcast();

  @override
  void initState() {
    // if (context.read<BranchController>().branchAllResponse == null) {
    //   BranchController.getAll(context, 1, 100).then((value) {
    //     if (responseCode(value.code)) {
    //       context.read<BranchController>().branchAllResponse = value;
    //       setState(() {});
    //     } else {
    //       //TODO: show error to retry
    //     }
    //   });
    // }
    widget.serviceBranch?.data?.sort((a, b) {
      final nameA = a.branchName?.toLowerCase() ?? '';
      final nameB = b.branchName?.toLowerCase() ?? '';
      return nameA.compareTo(nameB);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: screenHeight(90),
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 500,
                  child: CardContainer(
                    Column(
                      children: [
                        AppPadding.vertical(),
                        Text('List of branches', style: AppTypography.bodyLarge(context).apply()),
                        AppPadding.vertical(denominator: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Text(
                                'Service: ${widget.serviceBranch?.data?.first.serviceName}',
                                style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Total: ${widget.serviceBranch?.totalCount ?? '0'} branch(es)',
                                style: AppTypography.bodyMedium(context).apply(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: StreamBuilder<DateTime>(
                            stream: rebuild.stream,
                            builder: (context, snapshot) {
                              return SingleChildScrollView(
                                child: Column(
                                  children: [
                                    AppPadding.vertical(denominator: 2),
                                    for (service_branch_model.Data? item in widget.serviceBranch?.data ?? [])
                                      ListTile(
                                        onTap: () {
                                          showLoading();
                                          ServiceBranchAvailableDtController.get(
                                            context,
                                            1,
                                            100,
                                            serviceBranchId: item?.serviceBranchId,
                                          ).then((value) {
                                            dismissLoading();
                                            if (responseCode(value.code)) {
                                              DateTime now = DateTime.now();
                                              String? updateId;
                                              bool haveElements = false;
                                              try {
                                                updateId = value.data?.data
                                                    ?.firstWhere(
                                                      (element) => element.serviceBranchId == item?.serviceBranchId,
                                                    )
                                                    .serviceBranchAvailableDatetimeId;
                                              } catch (e) {
                                                debugPrint(e.toString());
                                              }
                                              try {
                                                if ((value.data?.data?.first.availableDatetimes?.length ?? 0) > 0) {
                                                  haveElements = true;
                                                }
                                              } catch (e) {
                                                debugPrint(e.toString());
                                              }
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return Row(
                                                    children: [
                                                      Expanded(
                                                        child: CardContainer(
                                                          Stack(
                                                            alignment: Alignment.topRight,
                                                            children: [
                                                              Container(
                                                                padding: EdgeInsets.all(screenPadding),
                                                                child: MultiTimeCalendarPage(
                                                                  serviceBranchId: item?.serviceBranchId ?? '',
                                                                  serviceBranchAvailableDatetimeId: updateId,
                                                                  startMonth: now.month,
                                                                  year: now.year,
                                                                  totalMonths: 3,
                                                                  initialDateTimes: haveElements
                                                                      ? value.data?.data?.first.availableDatetimes
                                                                      : null,
                                                                ),
                                                              ),
                                                              CloseButton(),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                  // return TimeListManager(
                                                  //   onChanged: () {
                                                  //     rebuild.add(DateTime.now());
                                                  //   },
                                                  //   serviceBranch: serviceBranch(
                                                  //     item?.branchId ?? ' ',
                                                  //     item?.serviceId ?? '',
                                                  //   ),
                                                  // );
                                                },
                                              );
                                            }
                                          });
                                        },
                                        title: Text('${item?.branchName}', style: AppTypography.bodyMedium(context)),
                                        trailing: CupertinoSwitch(
                                          value: item?.serviceBranchStatus == 1,
                                          onChanged: (value) async {
                                            try {
                                              if (await showConfirmDialog(
                                                context,
                                                item?.serviceBranchStatus == 1
                                                    ? 'Are you certain you wish to deactivate ${item?.serviceName} for ${item?.branchName}? Please note, this action can be reversed at a later time.'
                                                    : 'Are you certain you wish to activate ${item?.serviceName} for ${item?.branchName}? Please note, this action can be reversed at a later time.',
                                              )) {
                                                Future.delayed(Duration.zero, () {
                                                  ServiceBranchController.update(
                                                    context,
                                                    UpdateServiceBranchRequest(
                                                      serviceBranchId: item?.serviceBranchId,
                                                      serviceBranchAvailableTime: item?.serviceBranchAvailableTime,
                                                      serviceBranchStatus: item?.serviceBranchStatus == 1 ? 0 : 1,
                                                    ),
                                                  ).then((value) {
                                                    if (responseCode(value.code)) {
                                                      showLoading();
                                                      ServiceBranchController.getAll(
                                                        context,
                                                        1,
                                                        100,
                                                        serviceId: item?.serviceId,
                                                      ).then((value) {
                                                        dismissLoading();
                                                        context.read<ServiceBranchController>().serviceBranchResponse =
                                                            value.data;
                                                        rebuild.add(DateTime.now());
                                                        showDialogSuccess(
                                                          context,
                                                          '${item?.serviceName} has been successfully ${item?.serviceBranchStatus == 1 ? 'deactivated' : 'activated'} for ${item?.branchName}.',
                                                        );
                                                      });
                                                    } else {
                                                      showDialogError(
                                                        context,
                                                        value.message ?? value.data?.message ?? '',
                                                      );
                                                    }
                                                  });
                                                });
                                              }
                                            } catch (e) {
                                              debugPrint(e.toString());
                                            }
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  service_branch_model.Data serviceBranch(String branchId, String serviceId) {
    return context.read<ServiceBranchController>().serviceBranchResponse!.data!.firstWhere(
      (serviceBranch) => serviceBranch.branchId == branchId && serviceBranch.serviceId == serviceId,
    );
  }

  bool doesServiceBranchExistAndActive(String branchId) {
    return context.read<ServiceBranchController>().serviceBranchResponse!.data!.any(
      (serviceBranch) =>
          serviceBranch.branchId == branchId &&
          serviceBranch.serviceBranchStatus == 1 &&
          serviceBranch.branchStatus == 1 &&
          serviceBranch.serviceStatus == 1,
    );
  }
}
