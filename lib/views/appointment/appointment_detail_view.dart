import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/gestational/gestational_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_detail_response.dart';
import 'package:klinik_aurora_portal/views/appointment/rescan_appointment.dart';
import 'package:klinik_aurora_portal/views/widgets/button/copy_button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class AppointmentDetailsView extends StatefulWidget {
  final AppointmentDetailResponse? response;

  const AppointmentDetailsView({super.key, required this.response});

  @override
  State<AppointmentDetailsView> createState() => _AppointmentDetailsViewState();
}

class _AppointmentDetailsViewState extends State<AppointmentDetailsView> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: 800, maxHeight: 800),
              child: CardContainer(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(),
                            Row(
                              children: [
                                Text('Appointment Details', style: AppTypography.displayMedium(context)),
                                CopyButton(
                                  textToCopy:
                                      'Appointment Details\n\n${widget.response?.data?.user?.userFullName}\n${widget.response?.data?.user?.userPhone}\n${widget.response?.data?.user?.userEmail}\n${widget.response?.data?.service?.serviceName}\n${formatToDisplayDate(widget.response?.data?.appointmentDatetime ?? '')}\n${formatToDisplayTime(widget.response?.data?.appointmentDatetime ?? '')}\n${widget.response?.data?.branch?.branchName ?? ''}\nCreated Date : ${dateConverter(widget.response?.data?.createdDate ?? '')}\n',
                                  tooltip: 'Copy Appointment Details',
                                ),
                              ],
                            ),
                            CloseButton(
                              onPressed: () {
                                context.pop();
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                        // SECTION 1 - Patient & Branch
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _infoBlock("Patient Details", [
                                _infoRow(widget.response?.data?.user?.userFullName?.titleCase() ?? ''),
                                if (notNullOrEmptyString(widget.response?.data?.user?.userNric))
                                  _infoRow(widget.response?.data?.user?.userNric ?? ''),
                                _infoRow(widget.response?.data?.user?.userPhone ?? ''),
                                _infoRow(widget.response?.data?.user?.userEmail ?? ''),
                                const SizedBox(height: 12),
                                _infoLabel("Note"),
                                _infoRow(widget.response?.data?.appointmentNote ?? '-'),
                                const SizedBox(height: 12),
                                if (widget.response?.data?.service?.dueDateToggle == 1) ...[
                                  _infoLabel("Estimated Due Date (EDD)"),
                                  _infoRow(
                                    dateConverter(widget.response?.data?.customerDueDate, format: 'dd-MM-yyyy') ?? '-',
                                  ),
                                  const SizedBox(height: 12),
                                  if (notNullOrEmptyString(widget.response?.data?.service?.eddRequired)) ...[
                                    _infoLabel("Estimated gestational age at appointment"),
                                    _infoRow(
                                      calculateGestationalAge(
                                            edd: widget.response?.data?.customerDueDate ?? '',
                                            appointmentDate: widget.response?.data?.appointmentDatetime ?? '',
                                          ) ??
                                          '-',
                                    ),
                                  ],
                                ],
                                const SizedBox(height: 8),
                              ]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _infoBlock("Branch", [
                                _infoRow(widget.response?.data?.branch?.branchName ?? ''),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _infoLabel("Service"),
                                    if (widget.response?.data?.service?.serviceName?.toLowerCase().contains(
                                          'screening',
                                        ) ==
                                        true)
                                      TextButton(
                                        onPressed: () {
                                          showLoading();
                                          ServiceBranchController.rescanServiceBranchId(
                                            context,
                                            branchId: widget.response?.data?.branch?.branchId,
                                          ).then((value) {
                                            dismissLoading();
                                            showDialog(
                                              context: context,
                                              builder: (_) {
                                                return RescanAppointment(
                                                  appointment: widget.response,
                                                  serviceBranchId: value.data?.serviceBranchId ?? '',
                                                );
                                              },
                                            );
                                          });
                                        },
                                        child: Text(
                                          'Rescan',
                                          style: AppTypography.bodyMedium(
                                            context,
                                          ).apply(color: Colors.blue, fontWeightDelta: 1),
                                        ),
                                      ),
                                  ],
                                ),
                                _infoRow(
                                  '${widget.response?.data?.service?.serviceName}\nRM ${widget.response?.data?.service?.servicePrice}',
                                ),
                                const SizedBox(height: 12),
                                _infoLabel("Status"),
                                _infoRow(
                                  appointmentStatus
                                      .firstWhere((e) => widget.response?.data?.appointmentStatus?.toString() == e.key)
                                      .name,
                                  textColor: appointmentStatusColors[widget.response?.data?.appointmentStatus],
                                  bold: 1,
                                ),
                                const SizedBox(height: 12),
                                _infoLabel("Slots"),
                                _infoRow(
                                  dateConverter(
                                        widget.response?.data?.appointmentDatetime ?? '',
                                        format: 'dd-MM-yyyy HH:mm',
                                      ) ??
                                      '',
                                ),
                              ]),
                            ),
                          ],
                        ),

                        const Divider(height: 32),

                        // SECTION 2 - Payment
                        Row(
                          children: [
                            Expanded(
                              child: _infoBlock("Booking Fee", [
                                _infoRow("✅ Paid"),
                                const SizedBox(height: 8),
                                _infoLabel("Booking Fee Amount"),
                                _infoRow(widget.response?.data?.service?.serviceBookingFee ?? ''),
                                _infoLabel("Balance"),
                                _infoRow(
                                  'RM ${double.parse(widget.response?.data?.service?.servicePrice ?? '') - double.parse(widget.response?.data?.service?.serviceBookingFee ?? '')}',
                                ),
                              ]),
                            ),
                            Expanded(
                              child: _infoBlock("", [
                                _infoLabel("Created Date"),
                                _infoRow(dateConverter(widget.response?.data?.createdDate) ?? ''),
                                _infoLabel("Updated Date"),
                                _infoRow(dateConverter(widget.response?.data?.modifiedDate) ?? ''),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoBlock(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSelectableText(title, style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1)),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _infoRow(String value, {Color? textColor, int? bold}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: AppSelectableText(
        value,
        style: AppTypography.bodyMedium(context).apply(color: textColor, fontWeightDelta: bold ?? 0),
      ),
    );
  }

  Widget _infoLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: AppSelectableText(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AppSelectableText(text.isEmpty ? "—" : text, style: const TextStyle(fontSize: 14)),
    );
  }
}
