import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/controllers/gestational/gestational_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_detail_response.dart';
import 'package:klinik_aurora_portal/models/appointment/create_appointment_request.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/date_calendar_view.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class RescanAppointment extends StatefulWidget {
  final AppointmentDetailResponse? appointment;
  final String? serviceBranchId;
  const RescanAppointment({super.key, required this.appointment, required this.serviceBranchId});

  @override
  State<RescanAppointment> createState() => _RescanAppointmentState();
}

class _RescanAppointmentState extends State<RescanAppointment> {
  final TextEditingController noteController = TextEditingController();
  DropdownAttribute? selectedBranch;
  StreamController<DateTime> rebuild = StreamController.broadcast();
  DateTime? selectedDate;
  String? selectedTime;
  String? _selectedDateTime;
  GestationalController? gestationalResult;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CardContainer(
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                  width: screenWidth(40),
                  child: StreamBuilder(
                    stream: rebuild.stream,
                    builder: (context, asyncSnapshot) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _infoBlock("Patient Details", [
                            _infoRow(widget.appointment?.data?.first.user?.userFullName?.titleCase() ?? ''),
                            if (notNullOrEmptyString(widget.appointment?.data?.first.user?.userNric))
                              _infoRow(widget.appointment?.data?.first.user?.userNric ?? ''),
                            _infoRow(widget.appointment?.data?.first.user?.userPhone ?? ''),
                            _infoRow(widget.appointment?.data?.first.user?.userEmail ?? ''),
                          ]),
                          AppPadding.vertical(),
                          _infoBlock("Branch", [
                            _infoRow(widget.appointment?.data?.first.branch?.branchName ?? ''),
                            const SizedBox(height: 12),
                            _infoLabel("Service"),
                            _infoRow('Rescan - ${widget.appointment?.data?.first.service?.serviceName}\nRM 0.00'),
                          ]),
                          const SizedBox(height: 12),
                          if (widget.appointment?.data?.first.service?.dueDateToggle == 1) ...[
                            _infoLabel("Estimated Due Date (EDD)"),
                            _infoRow(
                              dateConverter(widget.appointment?.data?.first.customerDueDate, format: 'dd-MM-yyyy') ??
                                  '-',
                            ),
                            const SizedBox(height: 12),
                            if (notNullOrEmptyString(widget.appointment?.data?.first.service?.eddRequired)) ...[
                              _infoLabel("Estimated gestational age at appointment"),
                              if (notNullOrEmptyString(_selectedDateTime) &&
                                  notNullOrEmptyString(widget.appointment?.data?.first.customerDueDate))
                                _infoRow(
                                  calculateGestationalAge(
                                        edd:
                                            dateConverter(
                                              widget.appointment?.data?.first.customerDueDate,
                                              format: 'dd-MM-yyyy',
                                            ) ??
                                            '',
                                        appointmentDate: notNullOrEmptyString(_selectedDateTime)
                                            ? dateConverter(
                                                    DateFormat(
                                                      "dd-MM-yyyy HH:mm",
                                                    ).parse('$_selectedDateTime').toString(),
                                                    format: 'yyyy-MM-dd HH:mm:ss',
                                                  ) ??
                                                  '-'
                                            : '-',
                                      ) ??
                                      '-',
                                ),
                              Text(
                                getGestationalStatusMessage(
                                      result: gestationalResult,
                                      range: widget.appointment?.data?.first.service?.eddRequired ?? '',
                                      showRange: true,
                                    ) ??
                                    '',
                                style: AppTypography.bodyMedium(
                                  context,
                                ).apply(color: gestationalStatusColor(gestationalResult?.status)),
                              ),
                            ],
                          ],
                          AppPadding.vertical(),
                          _infoLabel("Note"),
                          _infoRow(widget.appointment?.data?.first.appointmentNote ?? '-'),
                          SizedBox(height: 16),
                          _infoLabel("Slot"),
                          Row(
                            children: [
                              (notNullOrEmptyString(_selectedDateTime))
                                  ? _infoRow('$_selectedDateTime')
                                  : _infoRow('-'),
                              SizedBox(width: 16),
                              ElevatedButton.icon(
                                style: ButtonStyle(
                                  padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  backgroundColor: WidgetStateProperty.all(secondaryColor),
                                ),
                                icon: Icon(Icons.calendar_today, color: Colors.white),
                                label: Text(
                                  'Select Slot',
                                  style: AppTypography.bodyMedium(
                                    context,
                                  ).apply(fontWeightDelta: 1, color: Colors.white),
                                ),
                                onPressed: () async {
                                  final selectedDate = await showDialog<String>(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: SelectionCalendarDateOnlyView(
                                          startMonth: DateTime.now().month,
                                          year: DateTime.now().year,
                                          totalMonths: 3,
                                          availableDates: [],
                                        ),
                                      ),
                                    ),
                                  );

                                  if (selectedDate != null) {
                                    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                    if (picked != null) {
                                      selectedTime = formatTimeOfDay(picked);
                                      _selectedDateTime = '$selectedDate $selectedTime';
                                      try {
                                        if (notNullOrEmptyString(widget.appointment?.data?.first.customerDueDate) &&
                                            notNullOrEmptyString(
                                              widget.appointment?.data?.first.service?.eddRequired,
                                            )) {
                                          gestationalResult = getGestationalStatusFromString(
                                            eddStr:
                                                dateConverter(
                                                  widget.appointment?.data?.first.customerDueDate,
                                                  format: 'dd-MM-yyyy',
                                                ) ??
                                                '',
                                            range:
                                                widget.appointment?.data?.first.service?.eddRequired ?? '26w0d-31w1d',
                                            appointmentDate: DateTime.parse(
                                              convertMalaysiaTimeToUtc(_selectedDateTime ?? '', plainFormat: true),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        debugPrint('$e');
                                      }
                                      rebuild.add(DateTime.now());
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 32),
                          Button(() {
                            if (notNullOrEmptyString(_selectedDateTime)) {
                              showConfirmDialog(
                                context,
                                "Are you sure you want to create a rescan appointment for ${widget.appointment?.data?.first.user?.userFullName?.titleCase()}",
                              ).then((value) {
                                if (value) {
                                  showLoading();
                                  AppointmentController.create(
                                    context,
                                    CreateAppointmentRequest(
                                      userId: widget.appointment?.data?.first.user?.userId,
                                      serviceBranchId: widget.serviceBranchId,
                                      appointmentDateTime: convertMalaysiaTimeToUtc(
                                        _selectedDateTime.toString(),
                                        plainFormat: true,
                                      ),
                                      appointmentNote: '',
                                      customerDueDate: dateConverter(
                                        widget.appointment?.data?.first.customerDueDate,
                                        format: 'dd-MM-yyyy',
                                      ),
                                      appointmentStatus: 1,
                                    ),
                                  ).then((createResponse) {
                                    dismissLoading();
                                    if (responseCode(createResponse.code)) {
                                      context.pop();
                                      showDialogSuccess(context, "Rescan appointment successfully created.");
                                    } else {
                                      showDialogError(context, createResponse.message ?? '');
                                    }
                                  });
                                }
                              });
                            } else {
                              showDialogError(context, ErrorMessage.required(field: 'Slot'));
                            }
                          }, actionText: 'Book'),
                          SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
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
}
