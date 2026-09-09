import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch_roster/branch_roster_controller.dart';
import 'package:klinik_aurora_portal/controllers/doctor/doctor_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/branch_roster/branch_roster_response.dart';
import 'package:klinik_aurora_portal/models/doctor/doctor_branch_response.dart' as doctor_model;
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';

class ShiftTimeSlot {
  TimeOfDay startTime;
  TimeOfDay endTime;

  ShiftTimeSlot({
    required this.startTime,
    required this.endTime,
  });
}

enum RosterViewMode { calendar, list }

class BranchRosterDialog extends StatefulWidget {
  final String? initialBranchId;
  final String? initialDoctorId;

  const BranchRosterDialog({
    super.key,
    this.initialBranchId,
    this.initialDoctorId,
  });

  @override
  State<BranchRosterDialog> createState() => _BranchRosterDialogState();
}

class _BranchRosterDialogState extends State<BranchRosterDialog> {
  String? _selectedBranchId;
  String? _selectedDoctorId;
  List<branch_model.Data> _branches = [];
  List<doctor_model.Data> _doctors = [];
  List<BranchRosterItem> _rosterShifts = [];
  bool _isLoadingShifts = false;
  bool _isLoadingDoctors = false;
  RosterViewMode _viewMode = RosterViewMode.calendar;

  // New Shift Form Fields: multi-date selection & customizable time slots
  List<DateTime> _selectedDates = [DateUtils.dateOnly(DateTime.now())];
  final List<ShiftTimeSlot> _timeSlots = [
    ShiftTimeSlot(
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 13, minute: 0),
    ),
  ];

  // Month filter for viewing
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    final userBranch = context.read<AuthController>().authenticationResponse?.data?.user?.branchId;
    _selectedBranchId = widget.initialBranchId ?? userBranch;
    _selectedDoctorId = widget.initialDoctorId;

    final cached = context.read<BranchController>().branchAllResponse?.data?.data;
    if (cached != null && cached.isNotEmpty) {
      _branches = cached;
      _selectedBranchId ??= cached.first.branchId;
    } else {
      BranchController.getAll(context, 1, 1000).then((val) {
        if (mounted && responseCode(val.code)) {
          setState(() {
            _branches = val.data?.data ?? [];
            _selectedBranchId ??= _branches.firstOrNull?.branchId;
          });
          if (_selectedBranchId != null && _doctors.isEmpty) {
            _loadDoctorsForBranch(_selectedBranchId!);
            _loadRosterShifts();
          }
        }
      });
    }

    if (_selectedBranchId != null) {
      _loadDoctorsForBranch(_selectedBranchId!);
      _loadRosterShifts();
    }
  }

  void _loadDoctorsForBranch(String branchId) {
    if (mounted) {
      setState(() => _isLoadingDoctors = true);
    } else {
      _isLoadingDoctors = true;
    }
    DoctorController.get(
      context,
      1,
      100,
      branchId: branchId,
      doctorStatus: 1,
    ).then((val) {
      if (mounted) {
        setState(() {
          _isLoadingDoctors = false;
          if (responseCode(val.code)) {
            _doctors = val.data?.data ?? [];
            if (_selectedDoctorId == null || !_doctors.any((d) => d.doctorId == _selectedDoctorId)) {
              _selectedDoctorId = _doctors.firstOrNull?.doctorId;
            }
          }
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isLoadingDoctors = false);
    });
  }

  void _loadRosterShifts() {
    if (_selectedBranchId == null) return;
    if (mounted) {
      setState(() => _isLoadingShifts = true);
    } else {
      _isLoadingShifts = true;
    }

    final startStr = DateFormat('yyyy-MM-dd').format(_currentMonth);
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    final endStr = DateFormat('yyyy-MM-dd').format(nextMonth.subtract(const Duration(days: 1)));

    BranchRosterController.get(
      context,
      branchId: _selectedBranchId!,
      startDate: startStr,
      endDate: endStr,
    ).then((val) {
      if (mounted) {
        setState(() {
          _isLoadingShifts = false;
          if (responseCode(val.code)) {
            _rosterShifts = val.data?.data ?? [];
          } else {
            _rosterShifts = [];
          }
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isLoadingShifts = false);
    });
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hourOfPeriod = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hourOfPeriod.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')} $period';
  }

  int? _parseTimeToMinutes(String? timeStr) {
    if (timeStr == null) return null;
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) return h * 60 + m;
    }
    return null;
  }

  void _handleAddTimeSlot() {
    if (_timeSlots.isEmpty) {
      setState(() {
        _timeSlots.add(ShiftTimeSlot(
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 13, minute: 0),
        ));
      });
      return;
    }

    final lastSlot = _timeSlots.last;
    final lastEndMinutes = lastSlot.endTime.hour * 60 + lastSlot.endTime.minute;
    // Suggest next slot starting 1 hour after previous slot (e.g. 1-hour break)
    final startMinutes = (lastEndMinutes + 60) % (24 * 60);
    final endMinutes = (startMinutes + 300) <= (24 * 60) ? (startMinutes + 300) : (23 * 60 + 59);

    final newStart = TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60);
    final newEnd = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);

    setState(() {
      _timeSlots.add(ShiftTimeSlot(startTime: newStart, endTime: newEnd));
    });
  }

  void _handleRemoveTimeSlot(int index) {
    if (_timeSlots.length <= 1) return;
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  Future<void> _handleSaveShift() async {
    if (_selectedBranchId == null || _selectedDoctorId == null) {
      showDialogError(context, 'Please select both a branch and a practitioner.');
      return;
    }

    if (_selectedDates.isEmpty) {
      showDialogError(context, 'Please select at least one shift date.');
      return;
    }

    final today = DateUtils.dateOnly(DateTime.now());
    if (_selectedDates.any((d) => DateUtils.dateOnly(d).isBefore(today))) {
      showDialogError(context, 'Past dates cannot be selected for shifts. Please select today or a future date.');
      return;
    }

    if (_timeSlots.isEmpty) {
      showDialogError(context, 'Please configure at least one time slot.');
      return;
    }

    // 1. Validate slot durations
    for (int i = 0; i < _timeSlots.length; i++) {
      final slot = _timeSlots[i];
      final startMinutes = slot.startTime.hour * 60 + slot.startTime.minute;
      final endMinutes = slot.endTime.hour * 60 + slot.endTime.minute;
      if (endMinutes <= startMinutes) {
        showDialogError(
          context,
          'Slot ${i + 1} (${_formatTimeOfDay(slot.startTime)} - ${_formatTimeOfDay(slot.endTime)}): End time must be after start time.',
        );
        return;
      }
    }

    // 2. Validate that slots in the form do not overlap each other
    for (int i = 0; i < _timeSlots.length; i++) {
      final sA = _timeSlots[i];
      final startA = sA.startTime.hour * 60 + sA.startTime.minute;
      final endA = sA.endTime.hour * 60 + sA.endTime.minute;

      for (int j = i + 1; j < _timeSlots.length; j++) {
        final sB = _timeSlots[j];
        final startB = sB.startTime.hour * 60 + sB.startTime.minute;
        final endB = sB.endTime.hour * 60 + sB.endTime.minute;

        if (startA < endB && endA > startB) {
          showDialogError(
            context,
            'Time Slot ${i + 1} (${_formatTimeOfDay(sA.startTime)} - ${_formatTimeOfDay(sA.endTime)}) overlaps with Slot ${j + 1} (${_formatTimeOfDay(sB.startTime)} - ${_formatTimeOfDay(sB.endTime)}).\n\nTime slots cannot overlap.',
          );
          return;
        }
      }
    }

    // 3. Check for overlaps with already scheduled shifts on those dates for this practitioner
    for (final date in _selectedDates) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      for (int i = 0; i < _timeSlots.length; i++) {
        final slot = _timeSlots[i];
        final startMinutes = slot.startTime.hour * 60 + slot.startTime.minute;
        final endMinutes = slot.endTime.hour * 60 + slot.endTime.minute;

        for (final existing in _rosterShifts) {
          if (existing.doctorId == _selectedDoctorId && existing.rosterDate == dateStr) {
            final exStart = _parseTimeToMinutes(existing.startTime);
            final exEnd = _parseTimeToMinutes(existing.endTime);
            if (exStart != null && exEnd != null) {
              if (startMinutes < exEnd && endMinutes > exStart) {
                showDialogError(
                  context,
                  'Slot ${i + 1} (${_formatTimeOfDay(slot.startTime)} - ${_formatTimeOfDay(slot.endTime)}) overlaps with an existing shift on $dateStr (${_formatTime(existing.startTime)} - ${_formatTime(existing.endTime)}).\n\nPlease remove or reschedule the existing shift first.',
                );
                return;
              }
            }
          }
        }
      }
    }

    // 4. Build batch payload (dates × slots)
    final List<RosterShiftPayload> payloads = [];
    for (final date in _selectedDates) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      for (final slot in _timeSlots) {
        final startStr = '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}:00';
        final endStr = '${slot.endTime.hour.toString().padLeft(2, '0')}:${slot.endTime.minute.toString().padLeft(2, '0')}:00';
        payloads.add(RosterShiftPayload(
          rosterDate: dateStr,
          startTime: startStr,
          endTime: endStr,
          maxConcurrent: 1,
        ));
      }
    }

    showLoading();
    final res = await BranchRosterController.bulkUpsert(
      context,
      branchId: _selectedBranchId!,
      doctorId: _selectedDoctorId!,
      shifts: payloads,
    );
    dismissLoading();

    if (!mounted) return;
    if (responseCode(res.code)) {
      final totalShifts = payloads.length;
      final datesCount = _selectedDates.length;
      final slotsCount = _timeSlots.length;
      showDialogSuccess(
        context,
        'Successfully added $totalShifts shift${totalShifts > 1 ? 's' : ''} ($slotsCount slot${slotsCount > 1 ? 's' : ''} across $datesCount date${datesCount > 1 ? 's' : ''}).',
      );
      if (_selectedDates.isNotEmpty) {
        final firstDate = _selectedDates.first;
        final shiftMonth = DateTime(firstDate.year, firstDate.month, 1);
        if (_currentMonth.year != shiftMonth.year || _currentMonth.month != shiftMonth.month) {
          _currentMonth = shiftMonth;
        }
      }
      _loadRosterShifts();
    } else {
      showDialogError(context, res.message ?? 'Failed to save shifts.');
    }
  }

  Future<void> _handleDeleteShift(BranchRosterItem item) async {
    final confirmed = await showConfirmDialog(
      context,
      'Are you sure you want to remove the shift for ${item.doctorName ?? 'this practitioner'} on ${item.rosterDate} (${item.startTime} - ${item.endTime})?',
    );

    if (confirmed == true && mounted) {
      showLoading();
      final res = await BranchRosterController.delete(context, rosterId: item.rosterId!);
      dismissLoading();

      if (!mounted) return;
      if (res.code == 409) {
        // Active bookings found!
        final data = res.data;
        final count = (data is Map) ? (data['affectedCount'] ?? 0) : 0;
        final list = (data is Map && data['affectedAppointments'] is List)
            ? (data['affectedAppointments'] as List)
            : [];
        final patientSummary = list.take(5).map((a) {
          final dt = a['appointmentDatetime']?.toString() ?? '';
          final timeStr = formatToDisplayTime(dt);
          return '• ${a['patientName']} ($timeStr)';
        }).join('\n');
        final moreNotice = list.length > 5 ? '\n...and ${list.length - 5} more.' : '';

        final proceed = await showConfirmDialog(
          context,
          '$count patient(s) are already booked during this shift:\n\n'
          '$patientSummary$moreNotice\n\n'
          'Deleting this shift will immediately block new bookings from patients.\n'
          'These appointments will be flagged in the appointment list for reassignment.\n\n'
          'Proceed to remove shift and block further bookings?',
          title: 'Active Bookings Found',
        );

        if (proceed == true && mounted) {
          showLoading();
          final forceRes = await BranchRosterController.delete(context, rosterId: item.rosterId!, force: true);
          dismissLoading();
          if (mounted && responseCode(forceRes.code)) {
            showDialogSuccess(context, 'Shift deleted. Bookings flagged for reassignment.');
            _loadRosterShifts();
          } else if (mounted) {
            showDialogError(context, forceRes.message ?? 'Failed to delete shift.');
          }
        }
      } else if (responseCode(res.code)) {
        showDialogSuccess(context, 'Shift deleted successfully.');
        _loadRosterShifts();
      } else {
        showDialogError(context, res.message ?? 'Failed to delete shift.');
      }
    }
  }

  Future<void> _handlePickDate() async {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);

    final results = await showCalendarDatePicker2Dialog(
      context: context,
      barrierDismissible: true,
      dialogBackgroundColor: Colors.white,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.multi,
        currentDate: today,
        selectedDayHighlightColor: primary,
        firstDate: today,
        lastDate: today.add(const Duration(days: 365)),
        selectableDayPredicate: (date) => !DateUtils.dateOnly(date).isBefore(today),
        openedFromDialog: true,
      ),
      value: _selectedDates.map(DateUtils.dateOnly).toList(),
      dialogSize: Size(
        screenWidthByBreakpoint(90, 70, 50),
        screenHeightByBreakpoint(90, 80, 50),
      ),
      borderRadius: BorderRadius.circular(20),
    );

    if (results != null && mounted) {
      final validDates = results
          .whereType<DateTime>()
          .map(DateUtils.dateOnly)
          .where((d) => !d.isBefore(today))
          .toList();
      validDates.sort((a, b) => a.compareTo(b));
      if (validDates.isNotEmpty) {
        setState(() => _selectedDates = validDates);
      }
    }
  }

  Future<void> _handlePickTime({required ShiftTimeSlot slot, required bool isStart}) async {
    final initialTime = isStart ? slot.startTime : slot.endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              surfaceTint: Colors.transparent,
              surfaceContainerHighest: Color(0xFFF3F4F6),
              onSurface: Color(0xFF1F2937),
              onSurfaceVariant: Color(0xFF4B5563),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFFF3F4F6);
                }
                return const Color(0xFFF9FAFB);
              }),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primary;
                }
                return const Color(0xFF1F2937);
              }),
              dialBackgroundColor: const Color(0xFFF9FAFB),
              dialHandColor: primary,
              dialTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return const Color(0xFF1F2937);
              }),
              dayPeriodBorderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFFF3F4F6);
                }
                return Colors.white;
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primary;
                }
                return const Color(0xFF4B5563);
              }),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          slot.startTime = picked;
        } else {
          slot.endTime = picked;
        }
      });
    }
  }

  // Helper to count how many distinct practitioners are on duty on a specific date to identify multi-staff capacity
  int _distinctStaffCountOnDate(String? dateStr) {
    if (dateStr == null) return 0;
    return _rosterShifts
        .where((s) => s.rosterDate == dateStr)
        .map((s) => s.doctorId)
        .whereType<String>()
        .toSet()
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = context.read<AuthController>().isSuperAdmin;
    final screenW = MediaQuery.of(context).size.width;
    final maxH = MediaQuery.of(context).size.height * 0.9;
    final maxW = isMobile ? screenW - 24 : math.min(screenW * 0.9, 1150.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 24,
      ),
      child: Container(
        width: maxW,
        height: maxH,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Main Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branch & Month Selector
                    _buildBranchAndMonthBar(isSuperAdmin),
                    const SizedBox(height: 16),

                    // Add Shift Form Card
                    _buildAddShiftCard(),
                    const SizedBox(height: 24),

                    // Shifts List Header & Table
                    _buildShiftsSection(),
                  ],
                ),
              ),
            ),

            // Footer
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Multi-staff capacity enables automatically whenever 2+ practitioners have active shifts.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Branch Practitioner Roster & Shifts',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Configure practitioner working shifts to enable multi-staff concurrent capacity',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchAndMonthBar(bool isSuperAdmin) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Branch selector (only enabled for superadmins)
          if (isSuperAdmin && _branches.isNotEmpty) ...[
            const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF4B5563)),
            const SizedBox(width: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _branches.any((b) => b.branchId == _selectedBranchId) ? _selectedBranchId : null,
                hint: const Text('Select Branch', style: TextStyle(fontSize: 13)),
                items: _branches.map((b) {
                  return DropdownMenuItem(
                    value: b.branchId,
                    child: Text(b.branchName ?? 'Unknown Branch', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null && val != _selectedBranchId) {
                    setState(() {
                      _selectedBranchId = val;
                      _loadDoctorsForBranch(val);
                      _loadRosterShifts();
                    });
                  }
                },
              ),
            ),
          ] else ...[
            const Icon(Icons.location_on_rounded, size: 18, color: primary),
            const SizedBox(width: 8),
            Text(
              _branches.firstWhere((b) => b.branchId == _selectedBranchId, orElse: () => branch_model.Data(branchName: 'Current Branch')).branchName ?? 'Current Branch',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ],
          const Spacer(),
          // Month navigation
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                _loadRosterShifts();
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_currentMonth),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                _loadRosterShifts();
              });
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF6B7280)),
            tooltip: 'Refresh shifts',
            onPressed: _loadRosterShifts,
          ),
        ],
      ),
    );
  }

  Widget _buildAddShiftCard() {
    final totalShiftsToCreate = _selectedDates.length * _timeSlots.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_circle_outline_rounded, size: 18, color: primary),
                  SizedBox(width: 8),
                  Text(
                    'Configure Practitioner Shifts',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_selectedDates.length} Date${_selectedDates.length > 1 ? 's' : ''} × ${_timeSlots.length} Slot${_timeSlots.length > 1 ? 's' : ''} = $totalShiftsToCreate Shift${totalShiftsToCreate > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Practitioner & Shift Dates
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              // Practitioner Dropdown
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Practitioner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4B5563))),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _doctors.any((d) => d.doctorId == _selectedDoctorId) ? _selectedDoctorId : null,
                          hint: Text(_isLoadingDoctors ? 'Loading staff...' : 'Select Doctor', style: const TextStyle(fontSize: 12)),
                          items: _doctors.map((d) {
                            return DropdownMenuItem(
                              value: d.doctorId,
                              child: Text(d.doctorName ?? 'Doctor', style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedDoctorId = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Shift Dates (Multi-Select)
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Shift Dates (Multi-Select)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4B5563))),
                        if (_selectedDates.length > 1)
                          InkWell(
                            onTap: () => setState(() => _selectedDates = [_selectedDates.first]),
                            child: const Text('Reset to 1 date', style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _handlePickDate,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 16, color: primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedDates.isEmpty
                                    ? 'Select Shift Dates'
                                    : _selectedDates.length == 1
                                        ? DateFormat('dd MMM yyyy (E)').format(_selectedDates.first)
                                        : '${_selectedDates.length} Dates Selected',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Select Dates',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: primary),
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

          // Selected Dates Chips
          if (_selectedDates.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedDates.map((d) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('dd MMM (E)').format(d),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          if (_selectedDates.length > 1) {
                            setState(() => _selectedDates.remove(d));
                          } else {
                            showDialogError(context, 'At least one shift date is required.');
                          }
                        },
                        child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),

          // Timing Section Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.schedule_rounded, size: 15, color: Color(0xFF4B5563)),
                  SizedBox(width: 6),
                  Text(
                    'Daily Shift Slots (Break Time Supported)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _handleAddTimeSlot,
                icon: const Icon(Icons.add_rounded, size: 14, color: primary),
                label: const Text('Add Time Slot (e.g. Break Time)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primary),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // List of Time Slots
          ...List.generate(_timeSlots.length, (index) {
            final slot = _timeSlots[index];

            Widget? breakIndicator;
            if (index > 0) {
              final prevSlot = _timeSlots[index - 1];
              final prevEndM = prevSlot.endTime.hour * 60 + prevSlot.endTime.minute;
              final curStartM = slot.startTime.hour * 60 + slot.startTime.minute;
              final gap = curStartM - prevEndM;
              if (gap > 0) {
                final gapH = gap ~/ 60;
                final gapM = gap % 60;
                breakIndicator = Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.coffee_rounded, size: 13, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(
                        'Break: ${_formatTimeOfDay(prevSlot.endTime)} - ${_formatTimeOfDay(slot.startTime)} (${gapH > 0 ? '${gapH}h ' : ''}${gapM > 0 ? '${gapM}m' : ''})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                      ),
                    ],
                  ),
                );
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?breakIndicator,
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: Text(
                          'Slot ${index + 1}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                        ),
                      ),

                      // Start Time Button
                      InkWell(
                        onTap: () => _handlePickTime(slot: slot, isStart: true),
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF6B7280)),
                              const SizedBox(width: 6),
                              Text(
                                _formatTimeOfDay(slot.startTime),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Text('to', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),

                      // End Time Button
                      InkWell(
                        onTap: () => _handlePickTime(slot: slot, isStart: false),
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF6B7280)),
                              const SizedBox(width: 6),
                              Text(
                                _formatTimeOfDay(slot.endTime),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Remove Slot Button
                      if (_timeSlots.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                          tooltip: 'Remove time slot',
                          onPressed: () => _handleRemoveTimeSlot(index),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 12),

          // Submit / Add Shifts Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _handleSaveShift,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                'Add Shifts ($totalShiftsToCreate)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Roster Shifts (${_rosterShifts.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                if (_rosterShifts.any((s) => _distinctStaffCountOnDate(s.rosterDate) >= 2)) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text(
                          'Multi-Staff Capacity Active',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // View Mode Toggle (Calendar vs List)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewModeButton(
                    icon: Icons.calendar_view_month_rounded,
                    label: 'Calendar',
                    isSelected: _viewMode == RosterViewMode.calendar,
                    onTap: () => setState(() => _viewMode = RosterViewMode.calendar),
                  ),
                  _buildViewModeButton(
                    icon: Icons.table_rows_rounded,
                    label: 'List',
                    isSelected: _viewMode == RosterViewMode.list,
                    onTap: () => setState(() => _viewMode = RosterViewMode.list),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingShifts)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_rosterShifts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: const [
                Icon(Icons.event_busy_rounded, size: 36, color: Color(0xFF9CA3AF)),
                SizedBox(height: 8),
                Text('No roster shifts configured for this month.', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                SizedBox(height: 4),
                Text('Add shifts using the form above. Without shifts, standard single-slot scheduling runs.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
          )
        else if (_viewMode == RosterViewMode.calendar)
          _buildCalendarView()
        else
          _buildListView(),
      ],
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? primary : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF111827) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDoctorColor(String? doctorId) {
    if (doctorId == null) return primary;
    const colors = [
      Color(0xFFDF6E98), // Aurora Pink
      Color(0xFF0D9488), // Teal
      Color(0xFF7C3AED), // Purple
      Color(0xFF2563EB), // Blue
      Color(0xFFD97706), // Amber
      Color(0xFF059669), // Emerald
    ];
    final index = _doctors.indexWhere((d) => d.doctorId == doctorId);
    if (index >= 0) return colors[index % colors.length];
    return primary;
  }

  Widget _buildCalendarView() {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayOfWeek = DateTime(year, month, 1).weekday; // 1 = Monday ... 7 = Sunday
    final leadingOffset = firstDayOfWeek - 1; // 0 = Mon ... 6 = Sun
    final totalCells = leadingOffset + daysInMonth;
    final totalWeeks = ((totalCells - 1) ~/ 7) + 1;

    final Map<String, List<BranchRosterItem>> shiftsByDate = {};
    for (final s in _rosterShifts) {
      if (s.rosterDate != null) {
        shiftsByDate.putIfAbsent(s.rosterDate!, () => []).add(s);
      }
    }
    for (final list in shiftsByDate.values) {
      list.sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
    }

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final calendarWidget = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Table(
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
            verticalInside: BorderSide(color: Color(0xFFE5E7EB)),
          ),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
            6: FlexColumnWidth(1),
          },
          children: [
            // Weekdays Header Row
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
              children: weekdays.asMap().entries.map((entry) {
                final idx = entry.key;
                final day = entry.value;
                final isWeekend = idx >= 5;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isWeekend ? primary : const Color(0xFF374151),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Week Rows
            ...List.generate(totalWeeks, (weekIndex) {
              return TableRow(
                children: List.generate(7, (dayIndex) {
                  final cellIndex = weekIndex * 7 + dayIndex;
                  final dayNumber = cellIndex - leadingOffset + 1;
                  final isWithinMonth = dayNumber >= 1 && dayNumber <= daysInMonth;

                  if (!isWithinMonth) {
                    return Container(
                      constraints: const BoxConstraints(minHeight: 110),
                      color: const Color(0xFFFAFAFA),
                    );
                  }

                  final cellDate = DateTime(year, month, dayNumber);
                  final dateStr = DateFormat('yyyy-MM-dd').format(cellDate);
                  final dayShifts = shiftsByDate[dateStr] ?? [];
                  final isToday = DateUtils.isSameDay(cellDate, DateTime.now());
                  final distinctDocs = dayShifts.map((s) => s.doctorId).whereType<String>().toSet().length;
                  final isDouble = distinctDocs >= 2;

                  return Container(
                    constraints: const BoxConstraints(minHeight: 110),
                    padding: const EdgeInsets.all(6),
                    color: isToday ? primary.withAlpha(8) : Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day Number & Double Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isToday ? primary : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                  color: isToday
                                      ? Colors.white
                                      : (dayIndex >= 5 ? primary : const Color(0xFF1F2937)),
                                ),
                              ),
                            ),
                            if (isDouble)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Text(
                                  '2 Staff',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Day Shifts List
                        ...dayShifts.map((shift) {
                          final docColor = _getDoctorColor(shift.doctorId);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                            decoration: BoxDecoration(
                              color: docColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: docColor.withAlpha(70)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shift.doctorName ?? 'Staff',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: docColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _handleDeleteShift(shift),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 2),
                                    child: Icon(Icons.close_rounded, size: 12, color: Colors.red.shade400),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 750,
          child: calendarWidget,
        ),
      );
    }

    return calendarWidget;
  }

  Widget _buildListView() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF374151)),
          dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Day')),
            DataColumn(label: Text('Practitioner')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Shift Hours')),
            DataColumn(label: Text('Action')),
          ],
          rows: _rosterShifts.map((shift) {
            final parsedDate = DateTime.tryParse(shift.rosterDate ?? '');
            final dayOfWeek = parsedDate != null ? DateFormat('EEEE').format(parsedDate) : '';
            final isWeekend = parsedDate != null && (parsedDate.weekday == DateTime.saturday || parsedDate.weekday == DateTime.sunday);
            final staffCount = _distinctStaffCountOnDate(shift.rosterDate);
            final isDouble = staffCount >= 2;

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(shift.rosterDate ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (isDouble) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text('$staffCount Staff (Concurrent)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                        ),
                      ],
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    dayOfWeek,
                    style: TextStyle(
                      color: isWeekend ? primary : const Color(0xFF374151),
                      fontWeight: isWeekend ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded, size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(shift.doctorName ?? 'Practitioner'),
                    ],
                  ),
                ),
                DataCell(_doctorTypeChip(shift.doctorType)),
                DataCell(Text('${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}')),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                    tooltip: 'Delete Shift',
                    onPressed: () => _handleDeleteShift(shift),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _doctorTypeChip(int? type) {
    final label = doctorType(type);
    Color bg = const Color(0xFFEFF6FF);
    Color fg = const Color(0xFF1D4ED8);
    switch (type) {
      case 2:
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7E22CE);
        break;
      case 3:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF047857);
        break;
      case 4:
        bg = const Color(0xFFFFF1F2);
        fg = const Color(0xFFBE123C);
        break;
      case 5:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      default:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  String _formatTime(String? t) {
    if (t == null || t.isEmpty) return '—';
    if (t.length >= 5) return t.substring(0, 5);
    return t;
  }
}
