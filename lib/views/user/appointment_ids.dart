import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/models/service_branch/service_branch_response.dart' as service_branch_model;
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/models/user/user_appointment_response.dart';
import 'package:klinik_aurora_portal/views/appointment/appointment_detail_view.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class UserAppointmentIds extends StatefulWidget {
  final UserAppointmentResponse? response;
  final UserResponse? patient;
  const UserAppointmentIds({super.key, required this.response, required this.patient});

  @override
  State<UserAppointmentIds> createState() => _UserAppointmentIdsState();
}

class _UserAppointmentIdsState extends State<UserAppointmentIds> {
  StreamController<DateTime> rebuild = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 500,
                child: CardContainer(
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppPadding.vertical(),
                        Text('List of appointment', style: AppTypography.bodyLarge(context).apply()),
                        AppPadding.vertical(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Text(
                                'Patient: ${widget.patient?.userFullname}',
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
                                'Total: ${widget.response?.total ?? '0'} appointment(s)',
                                style: AppTypography.bodyMedium(context).apply(),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<DateTime>(
                          stream: rebuild.stream,
                          builder: (context, snapshot) {
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  AppPadding.vertical(denominator: 2),
                                  for (Data? item in widget.response?.data ?? [])
                                    ListTile(
                                      onTap: () {
                                        showLoading();
                                        AppointmentController.detail(context, appointmentId: item?.appointmentId).then((
                                          value,
                                        ) {
                                          dismissLoading();
                                          if (responseCode(value.code)) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AppointmentDetailsView(response: value.data);
                                              },
                                            );
                                          }
                                        });
                                      },
                                      title: Text(
                                        '${dateConverter(item?.appointmentDatetime, format: 'dd-MM-yyyy HH:mm')}',
                                        style: AppTypography.bodyMedium(context),
                                      ),
                                      subtitle: Text(
                                        '${item?.appointmentId}',
                                        style: AppTypography.bodyMedium(
                                          context,
                                        ).apply(fontSizeDelta: -1, color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        AppPadding.vertical(denominator: 1 / 2),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
