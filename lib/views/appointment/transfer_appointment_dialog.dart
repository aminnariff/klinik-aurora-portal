import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_detail_response.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/selection_calendar_view.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class TransferAppointmentDialog extends StatefulWidget {
  final AppointmentDetailResponse? appointment;
  final VoidCallback? onTransferSuccess;

  const TransferAppointmentDialog({
    super.key,
    required this.appointment,
    this.onTransferSuccess,
  });

  @override
  State<TransferAppointmentDialog> createState() => _TransferAppointmentDialogState();
}

class _TransferAppointmentDialogState extends State<TransferAppointmentDialog> {
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();
  final StreamController<DateTime> rebuild = StreamController<DateTime>.broadcast();

  List<DropdownAttribute> targetBranches = [];
  DropdownAttribute? selectedTargetBranch;
  String? _selectedDateTime;
  bool _isLoadingBranches = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  @override
  void dispose() {
    reasonController.dispose();
    remarkController.dispose();
    rebuild.close();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    final currentBranchId = widget.appointment?.data?.branch?.branchId;
    try {
      final res = await BranchController.getAll(context, 1, 100, branchStatus: 1);
      if (responseCode(res.code) && res.data?.data != null) {
        final list = res.data!.data!
            .where((b) => b.branchId != currentBranchId)
            .map((b) => DropdownAttribute(b.branchId ?? '', b.branchName ?? ''))
            .toList();

        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (mounted) {
          setState(() {
            targetBranches = list;
            _isLoadingBranches = false;
          });
          rebuild.add(DateTime.now());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBranches = false);
      }
    }
  }

  List<String> _removePastDates(List<String> dateList) {
    final DateTime now = DateTime.now();
    return dateList.where((dateStr) {
      try {
        final DateTime date = DateTime.parse(dateStr).toLocal();
        return date.isAfter(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  String? _formatDateTimeToDisplay(String? input) {
    if (input == null || input.isEmpty) return '-';
    try {
      final inputFormat = DateFormat("yyyy-MM-dd HH:mm");
      final outputFormat = DateFormat("dd-MM-yyyy HH:mm");
      final dateTime = inputFormat.parse(input);
      return outputFormat.format(dateTime);
    } catch (_) {
      try {
        final dateTime = DateTime.parse(input);
        return DateFormat("dd-MM-yyyy HH:mm").format(dateTime);
      } catch (_) {
        return input;
      }
    }
  }

  Future<void> _pickSlot() async {
    if (selectedTargetBranch == null) {
      showDialogError(context, 'Please select the target branch first.');
      return;
    }

    final serviceId = widget.appointment?.data?.service?.serviceId;
    if (serviceId == null) {
      showDialogError(context, 'Service information is missing.');
      return;
    }

    showLoading();
    final slotResponse = await ServiceBranchAvailableDtController.getAvailableSlot(
      context,
      branchId: selectedTargetBranch!.key,
      serviceId: serviceId,
    );
    dismissLoading();

    if (!responseCode(slotResponse.code)) {
      showDialogError(
        context,
        slotResponse.message ??
            slotResponse.data?.message ??
            'This branch does not offer this service or has no active schedule.',
      );
      return;
    }

    List<String> availableSlots = slotResponse.data?.slots ?? [];
    availableSlots = _removePastDates(availableSlots);

    if (availableSlots.isEmpty) {
      showDialogError(
        context,
        'No available slots found for ${selectedTargetBranch!.name}. Please check branch roster or pick another branch.',
      );
      return;
    }

    availableSlots.sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    final DateTime now = DateTime.now();
    final pickedDateTime = await showDialog<String>(
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

    if (pickedDateTime != null) {
      setState(() {
        _selectedDateTime = pickedDateTime;
      });
      rebuild.add(DateTime.now());
    }
  }

  Future<void> _submitTransfer() async {
    if (selectedTargetBranch == null) {
      showDialogError(context, 'Please select the target branch.');
      return;
    }

    if (_selectedDateTime == null || _selectedDateTime!.isEmpty) {
      showDialogError(context, 'Please select an available timeslot at the target branch.');
      return;
    }

    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      showDialogError(context, 'Please enter the reason for transfer.');
      return;
    }

    final appointmentId = widget.appointment?.data?.appointmentId;
    if (appointmentId == null) {
      showDialogError(context, 'Appointment ID is missing.');
      return;
    }

    // Format target date time: "YYYY-MM-DD HH:mm:ss"
    String targetUtcDateTime = convertMalaysiaTimeToUtc(_selectedDateTime!, plainFormat: true);

    showLoading();
    try {
      final res = await AppointmentController.transfer(
        context,
        appointmentId: appointmentId,
        targetBranchId: selectedTargetBranch!.key,
        targetDateTime: targetUtcDateTime,
        transferReason: reason,
        adminRemark: remarkController.text.trim().isNotEmpty ? remarkController.text.trim() : null,
      );

      dismissLoading();

      if (responseCode(res.code)) {
        if (mounted) {
          final nav = Navigator.of(context, rootNavigator: true);
          Navigator.of(context).pop(); // close transfer dialog
          if (widget.onTransferSuccess != null) {
            widget.onTransferSuccess!();
          }
          showDialogSuccess(
            nav.context,
            'Appointment successfully transferred to ${selectedTargetBranch!.name}!',
          );
        }
      } else {
        showDialogError(
          context,
          res.message ?? res.data?['message'] ?? 'Failed to transfer appointment.',
        );
      }
    } catch (e) {
      dismissLoading();
      showDialogError(context, 'Error transferring appointment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final apptData = widget.appointment?.data;

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
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: isMobile ? 16 : 32),
                  width: screenWidthByBreakpoint(90, 70, 45, useAbsoluteValueDesktop: false),
                  child: StreamBuilder(
                    stream: rebuild.stream,
                    builder: (context, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.swap_horiz_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Transfer Appointment',
                                        style: AppTypography.titleLarge(context).apply(
                                          fontWeightDelta: 2,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Move this appointment to another branch',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
  tooltip: 'Tutup',
                                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFF1F5F9), height: 1),
                          const SizedBox(height: 16),

                          // Summary Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _summaryItem(
                                        'Patient',
                                        apptData?.user?.userFullName?.titleCase() ?? '—',
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                    Expanded(
                                      child: _summaryItem(
                                        'Contact',
                                        apptData?.user?.userPhone ?? '—',
                                        Icons.phone_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(color: Color(0xFFE2E8F0), height: 1),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _summaryItem(
                                        'Current Branch',
                                        apptData?.branch?.branchName ?? '—',
                                        Icons.business_rounded,
                                        color: const Color(0xFFDC2626),
                                      ),
                                    ),
                                    Expanded(
                                      child: _summaryItem(
                                        'Service',
                                        apptData?.service?.serviceName ?? '—',
                                        Icons.medical_services_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Target Branch Dropdown
                          _fieldLabel('Target Branch *'),
                          const SizedBox(height: 6),
                          _isLoadingBranches
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<DropdownAttribute>(
                                      isExpanded: true,
                                      hint: Text(
                                        'Select destination clinic branch...',
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                      ),
                                      value: selectedTargetBranch,
                                      items: targetBranches.map((b) {
                                        return DropdownMenuItem<DropdownAttribute>(
                                          value: b,
                                          child: Text(
                                            b.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          selectedTargetBranch = val;
                                          _selectedDateTime = null; // reset slot on branch change
                                        });
                                        rebuild.add(DateTime.now());
                                      },
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 16),

                          // Target Timeslot Selection
                          _fieldLabel('New Appointment Timeslot *'),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF64748B)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedDateTime != null
                                        ? _formatDateTimeToDisplay(_selectedDateTime)!
                                        : 'No slot selected',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedDateTime != null ? FontWeight.w600 : FontWeight.normal,
                                      color: _selectedDateTime != null
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  icon: const Icon(Icons.calendar_month_rounded, size: 15, color: Colors.white),
                                  label: const Text(
                                    'Pick Slot',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: _pickSlot,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Transfer Reason
                          _fieldLabel('Transfer Reason *'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: reasonController,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'e.g. Patient requested Cheras branch (closer to home/office)',
                              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: primary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Admin Remark (Optional)
                          _fieldLabel('Internal Admin Remark (Optional)'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: remarkController,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Optional staff notes',
                              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: primary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Notice Card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF1D4ED8)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This will vacate the current slot and reserve the new branch slot atomically. Existing deposit & payments will remain credited to this appointment. Patient will receive an updated push & email notification.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.blue.shade900,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Footer Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                label: const Text(
                                  'Confirm Transfer',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                onPressed: _submitTransfer,
                              ),
                            ],
                          ),
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

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF334155),
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color ?? const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: color ?? const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
