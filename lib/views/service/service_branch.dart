import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/service/services_response.dart' as service_model;
import 'package:klinik_aurora_portal/models/service_branch/service_branch_response.dart' as service_branch_model;
import 'package:klinik_aurora_portal/models/service_branch/update_service_branch_request.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class ServiceBranch extends StatefulWidget {
  final service_model.Data service;
  const ServiceBranch({
    super.key,
    required this.service,
  });

  @override
  State<ServiceBranch> createState() => _ServiceBranchState();
}

class _ServiceBranchState extends State<ServiceBranch> {
  StreamController<DateTime> rebuild = StreamController.broadcast();

  @override
  void initState() {
    if (context.read<BranchController>().branchAllResponse == null) {
      BranchController.getAll(context, 1, 100).then(
        (value) {
          if (responseCode(value.code)) {
            context.read<BranchController>().branchAllResponse = value;
            setState(() {});
          } else {
            //TODO: show error to retry
          }
        },
      );
    }
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
                        Text(
                          'List of branches',
                          style: AppTypography.bodyLarge(context).apply(),
                        ),
                        AppPadding.vertical(denominator: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Text(
                                'Service: ${widget.service.serviceName}',
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
                                'Total: ${context.read<BranchController>().branchAllResponse?.data?.totalCount ?? '0'} branch(es)',
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
                                      for (branch_model.Data? item
                                          in context.read<BranchController>().branchAllResponse?.data?.data ?? [])
                                        ListTile(
                                          onTap: () {
                                            //TODO: add timing
                                          },
                                          title: Text(
                                            '${item?.branchName}',
                                            style: AppTypography.bodyMedium(context),
                                          ),
                                          trailing: CupertinoSwitch(
                                            value: doesServiceBranchExistAndActive(item?.branchId ?? ''),
                                            onChanged: (value) async {
                                              try {
                                                service_branch_model.Data? data = serviceBranch(
                                                    item?.branchId ?? ' ', widget.service.serviceId ?? '');
                                                if (await showConfirmDialog(
                                                    context,
                                                    data.serviceBranchStatus == 1
                                                        ? 'Are you certain you wish to deactivate ${widget.service.serviceName} for ${item?.branchName}? Please note, this action can be reversed at a later time.'
                                                        : 'Are you certain you wish to activate ${widget.service.serviceName} for ${item?.branchName}? Please note, this action can be reversed at a later time.')) {
                                                  Future.delayed(Duration.zero, () {
                                                    ServiceBranchController.update(
                                                      context,
                                                      UpdateServiceBranchRequest(
                                                        serviceBranchId: data.serviceBranchId,
                                                        serviceBranchAvailableTime: data.serviceBranchAvailableTime,
                                                        serviceBranchStatus: data.serviceBranchStatus == 1 ? 0 : 1,
                                                      ),
                                                    ).then((value) {
                                                      if (responseCode(value.code)) {
                                                        showLoading();
                                                        ServiceBranchController.getAll(context, 1, 100,
                                                                serviceId: widget.service.serviceId,
                                                                serviceBranchStatus: 1)
                                                            .then((value) {
                                                          dismissLoading();
                                                          context
                                                              .read<ServiceBranchController>()
                                                              .serviceBranchResponse = value.data;
                                                          rebuild.add(DateTime.now());
                                                          showDialogSuccess(context,
                                                              '${widget.service.serviceName} has been successfully ${data.serviceBranchStatus == 1 ? 'deactivated' : 'activated'} for ${item?.branchName}.');
                                                        });
                                                      } else {
                                                        showDialogError(context, value.data?.message ?? '');
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
                              }),
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
    return context
        .read<ServiceBranchController>()
        .serviceBranchResponse!
        .data!
        .firstWhere((serviceBranch) => serviceBranch.branchId == branchId && serviceBranch.serviceId == serviceId);
  }

  bool doesServiceBranchExistAndActive(String branchId) {
    return context.read<ServiceBranchController>().serviceBranchResponse!.data!.any((serviceBranch) =>
        serviceBranch.branchId == branchId &&
        serviceBranch.serviceBranchStatus == 1 &&
        serviceBranch.branchStatus == 1 &&
        serviceBranch.serviceStatus == 1);
  }
}
