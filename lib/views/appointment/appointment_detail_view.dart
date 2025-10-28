import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/controllers/gestational/gestational_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_detail_response.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
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
                            Text('Appointment Details', style: AppTypography.displayMedium(context)),
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
                                _infoRow(widget.response?.data?.first.user?.userFullName ?? ''),
                                _infoRow(widget.response?.data?.first.user?.userPhone ?? ''),
                                _infoRow(widget.response?.data?.first.user?.userEmail ?? ''),
                                const SizedBox(height: 12),
                                _infoLabel("Note"),
                                _infoRow(widget.response?.data?.first.appointmentNote ?? '-'),
                                const SizedBox(height: 12),
                                if (widget.response?.data?.first.service?.dueDateToggle == 1) ...[
                                  _infoLabel("Estimated Due Date (EDD)"),
                                  _infoRow(
                                    dateConverter(widget.response?.data?.first.customerDueDate, format: 'dd-MM-yyyy') ??
                                        '-',
                                  ),
                                  const SizedBox(height: 12),
                                  if (notNullOrEmptyString(widget.response?.data?.first.service?.eddRequired)) ...[
                                    _infoLabel("Estimated gestational age at appointment"),
                                    _infoRow(
                                      calculateGestationalAge(
                                            edd: widget.response?.data?.first.customerDueDate ?? '',
                                            appointmentDate: widget.response?.data?.first.appointmentDatetime ?? '',
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
                                _infoRow(widget.response?.data?.first.branch?.branchName ?? ''),
                                const SizedBox(height: 12),
                                _infoLabel("Service"),
                                _infoRow(
                                  '${widget.response?.data?.first.service?.serviceName}\nRM ${widget.response?.data?.first.service?.servicePrice}',
                                ),
                                const SizedBox(height: 12),
                                _infoLabel("Status"),
                                _infoRow(
                                  appointmentStatus
                                      .firstWhere(
                                        (e) => widget.response?.data?.first.appointmentStatus?.toString() == e.key,
                                      )
                                      .name,
                                  textColor: appointmentStatusColors[widget.response?.data?.first.appointmentStatus],
                                  bold: 1,
                                ),
                                const SizedBox(height: 12),
                                _infoLabel("Slots"),
                                _infoRow(
                                  dateConverter(
                                        widget.response?.data?.first.appointmentDatetime ?? '',
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
                                _infoRow(widget.response?.data?.first.service?.serviceBookingFee ?? ''),
                                _infoLabel("Balance"),
                                _infoRow(
                                  'RM ${double.parse(widget.response?.data?.first.service?.servicePrice ?? '') - double.parse(widget.response?.data?.first.service?.serviceBookingFee ?? '')}',
                                ),
                              ]),
                            ),
                            Expanded(
                              child: _infoBlock("", [
                                _infoLabel("Created Date"),
                                _infoRow(dateConverter(widget.response?.data?.first.createdDate) ?? ''),
                                _infoLabel("Updated Date"),
                                _infoRow(dateConverter(widget.response?.data?.first.modifiedDate) ?? ''),
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
        Text(title, style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1)),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _infoRow(String value, {Color? textColor, int? bold}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        value,
        style: AppTypography.bodyMedium(context).apply(color: textColor, fontWeightDelta: bold ?? 0),
      ),
    );
  }

  Widget _infoLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
      child: Text(text.isEmpty ? "—" : text, style: const TextStyle(fontSize: 14)),
    );
  }
}
