import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/controllers/gestational/gestational_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_detail_response.dart';
import 'package:klinik_aurora_portal/models/appointment/create_appointment_request.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/selection_calendar_view.dart';
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
  final String? rescanServiceTime;
  const RescanAppointment({
    super.key,
    required this.appointment,
    required this.serviceBranchId,
    this.rescanServiceTime,
  });

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
  int _selectedDuration = 20;
  final List<int> _durationOptions = [15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    if (widget.rescanServiceTime != null) {
      final parsed = int.tryParse(widget.rescanServiceTime!.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null && parsed > 0) {
        if (!_durationOptions.contains(parsed)) {
          _durationOptions.add(parsed);
          _durationOptions.sort();
        }
        _selectedDuration = parsed;
      }
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    rebuild.close();
    super.dispose();
  }

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
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: isMobile ? 16 : 32),
                  width: screenWidthByBreakpoint(90, 70, 40, useAbsoluteValueDesktop: false),
                  child: StreamBuilder(
                    stream: rebuild.stream,
                    builder: (context, asyncSnapshot) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _infoBlock("Patient Details", [
                            _infoRow(widget.appointment?.data?.user?.userFullName?.titleCase() ?? ''),
                            if (notNullOrEmptyString(widget.appointment?.data?.user?.userNric))
                              _infoRow(widget.appointment?.data?.user?.userNric ?? ''),
                            _infoRow(widget.appointment?.data?.user?.userPhone ?? ''),
                            _infoRow(widget.appointment?.data?.user?.userEmail ?? ''),
                          ]),
                          AppPadding.vertical(),
                          _infoBlock("Branch", [
                            _infoRow(widget.appointment?.data?.branch?.branchName ?? ''),
                            const SizedBox(height: 12),
                            _infoLabel("Service"),
                            _infoRow(
                              'Rescan for ${widget.appointment?.data?.service?.serviceName ?? 'Scan'}\nRM 0.00',
                            ),
                            const SizedBox(height: 12),
                            _infoLabel("Rescan Duration"),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _durationOptions.map((mins) {
                                final isSelected = _selectedDuration == mins;
                                return ChoiceChip(
                                  label: Text('$mins mins'),
                                  selected: isSelected,
                                  selectedColor: secondaryColor,
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF374151),
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSelected ? secondaryColor : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedDuration = mins;
                                        _selectedDateTime = null;
                                      });
                                      rebuild.add(DateTime.now());
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          if (widget.appointment?.data?.service?.dueDateToggle == 1) ...[
                            _infoLabel("Estimated Due Date (EDD)"),
                            _infoRow(
                              dateConverter(widget.appointment?.data?.customerDueDate, format: 'dd-MM-yyyy') ?? '-',
                            ),
                            const SizedBox(height: 12),
                            if (notNullOrEmptyString(widget.appointment?.data?.service?.eddRequired)) ...[
                              _infoLabel("Estimated gestational age at appointment"),
                              if (notNullOrEmptyString(_selectedDateTime) &&
                                  notNullOrEmptyString(widget.appointment?.data?.customerDueDate))
                                _infoRow(
                                  calculateGestationalAge(
                                        edd:
                                            dateConverter(
                                              widget.appointment?.data?.customerDueDate,
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
                                      range: widget.appointment?.data?.service?.eddRequired ?? '',
                                      showRange: true,
                                    ) ??
                                    '',
                                style: AppTypography.bodyMedium(
                                  context,
                                ).apply(color: gestationalStatusColor(gestationalResult?.status)),
                              ),
                            ],
                          ],
                          if (notNullOrEmptyString(widget.appointment?.data?.appointmentNote)) ...[
                            AppPadding.vertical(),
                            _infoLabel("Original Appointment Note"),
                            _infoRow(widget.appointment?.data?.appointmentNote ?? '-'),
                          ],
                          AppPadding.vertical(),
                          _infoLabel("Rescan Reason / Note (Optional)"),
                          const SizedBox(height: 4),
                          TextField(
                            controller: noteController,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'e.g. Baby position uncooperative (Optional)',
                              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: secondaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _infoLabel("Slot"),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              (notNullOrEmptyString(_selectedDateTime))
                                  ? _infoRow('${formatDateTimeToDisplay(_selectedDateTime)}')
                                  : _infoRow('-'),
                              ElevatedButton.icon(
                                style: ButtonStyle(
                                  padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  backgroundColor: WidgetStateProperty.all(secondaryColor),
                                  shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                                icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                                label: Text(
                                  'Select Slot',
                                  style: AppTypography.bodyMedium(
                                    context,
                                  ).apply(fontWeightDelta: 1, color: Colors.white),
                                ),
                                onPressed: () async {
                                  if (widget.serviceBranchId == null) {
                                    showDialogError(context, 'Rescan service branch ID is missing');
                                    return;
                                  }

                                  showLoading();
                                  final slotServiceBranchId =
                                      widget.appointment?.data?.serviceBranchId ?? widget.serviceBranchId;
                                  final slotResponse = await ServiceBranchAvailableDtController.getAvailableSlot(
                                    context,
                                    serviceBranchId: slotServiceBranchId,
                                    serviceTime: '$_selectedDuration minutes',
                                    durationMinutes: _selectedDuration,
                                  );
                                  dismissLoading();

                                  if (!responseCode(slotResponse.code)) {
                                    showDialogError(
                                      context,
                                      slotResponse.message ??
                                          slotResponse.data?.message ??
                                          'Failed to retrieve available slots',
                                    );
                                    return;
                                  }

                                  List<String> availableSlots = slotResponse.data?.slots ?? [];
                                  availableSlots = removePastDates(availableSlots);

                                  if (availableSlots.isEmpty) {
                                    showDialogError(
                                      context,
                                      'No available slots found for this branch and service. Please check branch schedule or practitioner roster.',
                                    );
                                    return;
                                  }

                                  availableSlots.sort(
                                    (a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)),
                                  );

                                  final DateTime now = DateTime.now();
                                  final selectedDateTime = await showDialog<String>(
                                    context: context,
                                    builder: (BuildContext dialogContext) {
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                constraints: BoxConstraints(
                                                  maxWidth: isMobile ? screenWidth(92) : 560.0,
                                                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
                                                ),
                                                child: CardContainer(
                                                  SingleChildScrollView(
                                                    padding: EdgeInsets.all(isMobile ? 12 : 20),
                                                    child: SelectionCalendarView(
                                                      startMonth: now.month,
                                                      year: now.year,
                                                      initialDateTimes: availableSlots,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (selectedDateTime != null) {
                                    _selectedDateTime = selectedDateTime;
                                    try {
                                      if (notNullOrEmptyString(widget.appointment?.data?.customerDueDate) &&
                                          notNullOrEmptyString(widget.appointment?.data?.service?.eddRequired)) {
                                        gestationalResult = getGestationalStatusFromString(
                                          eddStr:
                                              dateConverter(
                                                widget.appointment?.data?.customerDueDate,
                                                format: 'dd-MM-yyyy',
                                              ) ??
                                              '',
                                          range: widget.appointment?.data?.service?.eddRequired ?? '26w0d-31w1d',
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
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                          Center(
                            child: Button(
                              () {
                                if (notNullOrEmptyString(_selectedDateTime)) {
                                  showConfirmDialog(
                                    context,
                                    "Are you sure you want to create a rescan appointment for ${widget.appointment?.data?.user?.userFullName?.titleCase()}",
                                  ).then((value) {
                                    if (value) {
                                      final utcDateTime = convertMalaysiaTimeToUtc(
                                        _selectedDateTime.toString(),
                                        plainFormat: true,
                                      );

                                      if (utcDateTime.isEmpty) {
                                        showDialogError(context, "Invalid appointment datetime format selected");
                                        return;
                                      }

                                      final patientUserId = widget.appointment?.data?.user?.userId;
                                      if (patientUserId == null || patientUserId.isEmpty) {
                                        showDialogError(context, "Patient user ID is missing from original appointment");
                                        return;
                                      }

                                      showLoading();
                                      final parentId = widget.appointment?.data?.appointmentId ?? '';
                                      final reason = noteController.text.trim();
                                      final parentServiceName = widget.appointment?.data?.service?.serviceName ?? 'Scan';
                                      final shortId = parentId.length > 8 ? parentId.substring(0, 8) : parentId;
                                      final notePrefix = shortId.isNotEmpty
                                          ? 'Rescan for $parentServiceName (Appt #$shortId)'
                                          : 'Rescan for $parentServiceName';
                                      final fullNote = reason.isNotEmpty ? '$notePrefix: $reason' : notePrefix;
                                      final adminRemark = parentId.isNotEmpty ? 'Parent Appointment ID: $parentId' : null;

                                      AppointmentController.create(
                                        context,
                                        CreateAppointmentRequest(
                                          userId: patientUserId,
                                          serviceBranchId: widget.serviceBranchId,
                                          appointmentDateTime: utcDateTime,
                                          appointmentNote: fullNote,
                                          adminRemark: adminRemark,
                                          customerDueDate: dateConverter(
                                            widget.appointment?.data?.customerDueDate,
                                            format: 'dd-MM-yyyy',
                                          ),
                                          appointmentStatus: 1,
                                          serviceTime: '$_selectedDuration minutes',
                                        ),
                                      ).then((createResponse) {
                                        dismissLoading();
                                        if (responseCode(createResponse.code)) {
                                          context.pop();
                                          showDialogSuccess(context, "Rescan appointment successfully created.");
                                        } else {
                                          showDialogError(
                                            context,
                                            createResponse.message ??
                                                createResponse.data?.message ??
                                                'Failed to create rescan appointment',
                                          );
                                        }
                                      }).catchError((e) {
                                        dismissLoading();
                                        showDialogError(context, e.toString());
                                      });
                                    }
                                  });
                                } else {
                                  showDialogError(context, ErrorMessage.required(field: 'Slot'));
                                }
                              },
                              actionText: 'Book',
                              width: 160,
                              borderRadius: 6,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 32),
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

  List<String> removePastDates(List<String> dateList) {
    DateTime now = DateTime.now();
    return dateList.where((dateStr) {
      try {
        DateTime date = DateTime.parse(dateStr).toLocal();
        return date.isAfter(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  String? formatDateTimeToDisplay(String? input) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$');
    if (!regex.hasMatch(input ?? '')) {
      return input;
    }
    try {
      final inputFormat = DateFormat("yyyy-MM-dd HH:mm");
      final outputFormat = DateFormat("dd-MM-yyyy HH:mm");
      final dateTime = inputFormat.parse(input ?? '');
      return outputFormat.format(dateTime);
    } catch (e) {
      return input;
    }
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
