import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/models/service_branch/service_branch_response.dart' as sb_model;
import 'package:klinik_aurora_portal/views/service/slot_generator.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class TimeSlotDates {
  final TimeOfDay time;
  final Map<String, bool> selectedDates;

  TimeSlotDates({required this.time, required this.selectedDates});
}

class MultiTimeCalendarPage extends StatefulWidget {
  final String serviceBranchId;
  final String serviceTiming;
  final String? serviceBranchAvailableDatetimeId;
  final int startMonth;
  final int year;
  final int totalMonths;
  final List<String>? initialDateTimes;
  final String? branchId;

  const MultiTimeCalendarPage({
    super.key,
    required this.serviceBranchId,
    required this.serviceTiming,
    this.serviceBranchAvailableDatetimeId,
    required this.startMonth,
    required this.year,
    this.totalMonths = 2,
    this.initialDateTimes,
    this.branchId,
  });

  @override
  State<MultiTimeCalendarPage> createState() => _MultiTimeCalendarPageState();
}

class _MultiTimeCalendarPageState extends State<MultiTimeCalendarPage> {
  final List<TimeSlotDates> timeSlots = [];
  final DateTime today = DateTime.now();
  int currentMonthIndex = 0;
  bool _clipboardHasData = false;

  @override
  void initState() {
    super.initState();
    currentMonthIndex = DateTime.now().month - widget.startMonth;
    currentMonthIndex = currentMonthIndex.clamp(0, widget.totalMonths - 1);
    if (widget.initialDateTimes != null) {
      _loadInitialSelections(widget.initialDateTimes!);
    }
    _checkClipboard();
  }

  void _checkClipboard() {
    final saved = prefs.getStringList('slot_clipboard');
    if (saved != null && saved.isNotEmpty) {
      setState(() => _clipboardHasData = true);
    }
  }

  void _loadInitialSelections(List<String> dateTimes) {
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      final Map<String, TimeSlotDates> timeMap = {};
      for (var iso in dateTimes) {
        try {
          final dt = DateTime.parse(iso).toLocal();
          final time = TimeOfDay(hour: dt.hour, minute: dt.minute);
          final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          final timeKey = time.format(context);

          if (!timeMap.containsKey(timeKey)) {
            timeMap[timeKey] = TimeSlotDates(time: time, selectedDates: {});
          }
          timeMap[timeKey]!.selectedDates[key] = true;
        } catch (e) {
          debugPrint('SKIP $e');
        }
      }

      final sortedList = timeMap.values.toList()
        ..sort((a, b) => (a.time.hour * 60 + a.time.minute).compareTo(b.time.hour * 60 + b.time.minute));

      setState(() {
        timeSlots.addAll(sortedList);
      });
    });
  }

  Future<TimeOfDay?> _showTimePicker(TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: secondaryColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF111827),
          ),
          timePickerTheme: const TimePickerThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
  }

  void _addTimeSlot() async {
    final picked = await _showTimePicker(TimeOfDay.now());
    if (picked != null) {
      final exists = timeSlots.any((t) => t.time.hour == picked.hour && t.time.minute == picked.minute);
      if (exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This time slot already exists.')));
        return;
      }
      setState(() {
        timeSlots.add(TimeSlotDates(time: picked, selectedDates: {}));
        timeSlots.sort((a, b) => (a.time.hour * 60 + a.time.minute).compareTo(b.time.hour * 60 + b.time.minute));
      });
    }
  }

  List<String> _getAllDateTimeValues() {
    final result = <String>[];
    for (var slot in timeSlots) {
      slot.selectedDates.forEach((dateStr, selected) {
        if (selected) {
          final parts = dateStr.split('-').map(int.parse).toList();
          final dt = DateTime(parts[0], parts[1], parts[2], slot.time.hour, slot.time.minute);
          result.add(dt.toUtc().toIso8601String());
        }
      });
    }
    return result;
  }

  List<String> filterPastMonths(List<String> isoDates, {DateTime? nowOverride}) {
    final nowLocal = (nowOverride ?? DateTime.now()).toLocal();
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    // Final Logic: Remove ALL past dates.
    // If today is 28th March, any date BEFORE 28th March is removed.
    // We only care about today and the future since past dates aren't bookable.
    return isoDates.where((s) {
      try {
        final dtLocal = DateTime.parse(s).toLocal();
        final slotDate = DateTime(dtLocal.year, dtLocal.month, dtLocal.day);
        return !slotDate.isBefore(today);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  void _saveToClipboard() async {
    final slots = _getAllDateTimeValues();
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No slots to save.')));
      return;
    }
    await prefs.setStringList('slot_clipboard', slots);
    setState(() => _clipboardHasData = true);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Slots saved to clipboard.'), backgroundColor: Color(0xFF16A34A)));
  }

  void _loadFromClipboard() async {
    final saved = prefs.getStringList('slot_clipboard');
    if (saved == null || saved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No saved slots found.')));
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      'Load ${saved.length} slots from clipboard? This will REPLACE your current configuration.',
    );
    if (!confirmed) return;
    setState(() => timeSlots.clear());
    _loadInitialSelections(saved);
  }

  void _showApplyToServicesDialog() async {
    final rawSlots = _getAllDateTimeValues();
    if (rawSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No slots configured.')));
      return;
    }
    final slots = filterPastMonths(rawSlots);
    if (widget.branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branch info not available.')));
      return;
    }

    showLoading();
    final result = await ServiceBranchController.getAll(context, 1, 100, branchId: widget.branchId);
    dismissLoading();
    if (!mounted) return;

    if (!responseCode(result.code)) {
      showDialogError(context, result.message ?? 'Failed to load services.');
      return;
    }

    final allServices = result.data?.data ?? [];
    final otherServices = allServices
        .where((s) => s.serviceBranchId != widget.serviceBranchId && s.serviceBranchStatus == 1)
        .toList();

    if (otherServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No other active services found.')));
      return;
    }

    final Map<String, bool> selected = {for (var s in otherServices) (s.serviceBranchId ?? ''): false};

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ApplyToServicesDialog(services: otherServices, selectedMap: selected, slotCount: slots.length),
    );

    if (confirmed != true) return;
    final selectedServices = otherServices.where((s) => selected[s.serviceBranchId ?? ''] == true).toList();
    if (selectedServices.isEmpty) return;

    showLoading();
    int successCount = 0;
    for (final svc in selectedServices) {
      try {
        final id = svc.serviceBranchId ?? '';
        final existingResult = await ServiceBranchAvailableDtController.get(context, 1, 1, serviceBranchId: id);
        final existingId = existingResult.data?.data?.isNotEmpty == true
            ? existingResult.data!.data!.first.serviceBranchAvailableDatetimeId
            : null;
        final r = existingId != null
            ? await ServiceBranchAvailableDtController.update(context, existingId, id, slots)
            : await ServiceBranchAvailableDtController.create(context, id, slots);
        if (responseCode(r.code)) successCount++;
      } catch (_) {}
    }
    dismissLoading();
    if (!mounted) return;
    showDialogSuccess(context, 'Slots applied to $successCount services successfully.');
  }

  void _saveSlots() async {
    if (!await showConfirmDialog(
      context,
      'Are you sure you want to ${widget.serviceBranchAvailableDatetimeId == null ? 'create' : 'update'} the available time slots?',
    ))
      return;
    showLoading();
    final updatedSlots = filterPastMonths(_getAllDateTimeValues());
    final result = widget.serviceBranchAvailableDatetimeId == null
        ? await ServiceBranchAvailableDtController.create(context, widget.serviceBranchId, updatedSlots)
        : await ServiceBranchAvailableDtController.update(
            context,
            widget.serviceBranchAvailableDatetimeId!,
            widget.serviceBranchId,
            updatedSlots,
          );
    dismissLoading();
    if (responseCode(result.code)) {
      showDialogSuccess(context, 'Successfully saved the available appointment slots.');
    } else {
      showDialogError(context, result.message ?? 'Unable to save slots.');
    }
  }

  @override
  Widget build(BuildContext context) {
    int displayMonth = widget.startMonth + currentMonthIndex;
    int displayYear = widget.year + ((displayMonth - 1) ~/ 12);
    displayMonth = ((displayMonth - 1) % 12) + 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                // Header / Month Nav
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.calendar_month_rounded, color: secondaryColor, size: 20),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(DateTime(displayYear, displayMonth)),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      const Spacer(),
                      _utilityIconBtn(
                        icon: Icons.help_outline_rounded,
                        label: 'Help',
                        onTap: () => _showHelpGuide(context),
                        color: Colors.orange[700]!,
                      ),
                      const SizedBox(width: 8),
                      _navBtn(
                        icon: Icons.chevron_left_rounded,
                        onTap: currentMonthIndex > 0 ? () => setState(() => currentMonthIndex--) : null,
                      ),
                      const SizedBox(width: 8),
                      _navBtn(
                        icon: Icons.chevron_right_rounded,
                        onTap: currentMonthIndex < widget.totalMonths - 1
                            ? () => setState(() => currentMonthIndex++)
                            : null,
                      ),
                    ],
                  ),
                ),
                // Slots List
                Expanded(
                  child: timeSlots.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_note_rounded, size: 64, color: Colors.grey[200]),
                              const SizedBox(height: 16),
                              Text(
                                'No slots configured',
                                style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: timeSlots.length,
                          itemBuilder: (context, index) {
                            final slot = timeSlots[index];
                            final selectedCount = slot.selectedDates.values.where((v) => v).length;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFF3F4F6)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: secondaryColor.withAlpha(20),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.access_time_filled_rounded,
                                            color: secondaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              slot.time.format(context),
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                            ),
                                            Text(
                                              '$selectedCount dates picked',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        _cardActionBtn(
                                          icon: Icons.edit_note_rounded,
                                          color: const Color(0xFF6366F1),
                                          onTap: () async {
                                            final picked = await _showTimePicker(slot.time);
                                            if (picked != null) {
                                              final otherIdx = timeSlots.indexWhere(
                                                (t) => t.time.hour == picked.hour && t.time.minute == picked.minute,
                                              );
                                              if (otherIdx != -1 && otherIdx != index) {
                                                if (await showConfirmDialog(
                                                  context,
                                                  'Merge with existing ${picked.format(context)} slot?',
                                                )) {
                                                  setState(() {
                                                    timeSlots[otherIdx].selectedDates.addAll(slot.selectedDates);
                                                    timeSlots.removeAt(index);
                                                  });
                                                }
                                                return;
                                              }
                                              setState(
                                                () => timeSlots[index] = TimeSlotDates(
                                                  time: picked,
                                                  selectedDates: Map.from(slot.selectedDates),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        _cardActionBtn(
                                          icon: Icons.delete_sweep_rounded,
                                          color: Colors.redAccent,
                                          onTap: () async {
                                            if (await showConfirmDialog(context, 'Remove this slot?'))
                                              setState(() => timeSlots.removeAt(index));
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _buildCalendar(slot.selectedDates, displayMonth, displayYear),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, -5)),
                    ],
                  ),
                  child: Row(
                    children: [
                      _secondaryBtn(icon: Icons.copy_all_rounded, label: 'Save All', onTap: _saveToClipboard),
                      const SizedBox(width: 8),
                      if (_clipboardHasData)
                        _secondaryBtn(icon: Icons.paste_rounded, label: 'Load Saved', onTap: _loadFromClipboard),
                      const Spacer(),
                      _utilityIconBtn(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Generator',
                        onTap: _openGenerator,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      _utilityIconBtn(
                        icon: Icons.more_time_rounded,
                        label: 'Add Time',
                        onTap: _addTimeSlot,
                        color: const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 16),
                      Button(
                        _saveSlots,
                        actionText: widget.serviceBranchAvailableDatetimeId == null
                            ? 'Create Calendar'
                            : 'Update Calendar',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sidebar
          Container(
            width: 320,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Summary', style: AppTypography.displayMedium(context)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: secondaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_getAllDateTimeValues().length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: secondaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Overview of scheduled appointments.', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 20),
                Expanded(child: _buildDateGroupedSummary()),
                if (widget.branchId != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _secondaryBtn(
                      icon: Icons.sync_rounded,
                      label: 'Sync other services',
                      onTap: _showApplyToServicesDialog,
                      highlight: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_center_rounded, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  Text('Calendar Guide', style: AppTypography.displayMedium(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Master your branch schedule with these simple steps:',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _guideStep(
                1,
                'Add Time Slots',
                'Add specific times (e.g., 09:00 AM) using the "Add Time" button or use the "Generator" for automated bulk setup.',
              ),
              _guideStep(
                2,
                'Select Dates',
                'For each time slot, click on dates in the calendar to enable it. You can only pick Today and future dates.',
              ),
              _guideStep(
                3,
                'Review Summary',
                'The right sidebar shows a live overview of your schedule. This helps spot gaps or Practitioner overlaps quickly.',
              ),
              _guideStep(
                4,
                'Save & Sync',
                'Upon "Update Calendar", you can "Sync" the configuration to other services. Useful for applying a common schedule to various doctor types in one go.',
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                '💡 Tip: Data is automatically pruned! We only keep Today and Future dates to save storage and optimize performance.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: secondaryColor.withAlpha(20),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Got it!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: secondaryColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideStep(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBtn({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey[100] : secondaryColor.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? Colors.grey[400] : secondaryColor),
      ),
    );
  }

  Widget _cardActionBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _utilityIconBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final color = highlight ? const Color(0xFF6366F1) : const Color(0xFF374151);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(50)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(Map<String, bool> selectedDates, int month, int year) {
    DateTime firstDay = DateTime(year, month, 1);
    int daysInMonth = DateTime(year, month + 1, 0).day;
    int startWeekday = firstDay.weekday % 7;
    List<TableRow> rows = [];
    List<String> dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    rows.add(
      TableRow(
        children: dayLabels
            .map(
              (d) => Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    d.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[400],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
    int dayCount = 1;
    for (int i = 0; i < 6; i++) {
      List<Widget> week = [];
      for (int j = 0; j < 7; j++) {
        if ((i == 0 && j < startWeekday) || dayCount > daysInMonth) {
          week.add(const SizedBox(height: 32));
        } else {
          final day = dayCount;
          final key = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          final isSelected = selectedDates[key] == true;
          final isToday = today.year == year && today.month == month && today.day == day;
          final isPast = DateTime(year, month, day).isBefore(DateTime(today.year, today.month, today.day));
          week.add(
            Center(
              child: InkWell(
                onTap: isPast ? null : () => setState(() => selectedDates[key] = !isSelected),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? secondaryColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday ? Border.all(color: secondaryColor.withAlpha(100)) : null,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isPast ? Colors.grey[300] : (isToday ? secondaryColor : const Color(0xFF374151))),
                    ),
                  ),
                ),
              ),
            ),
          );
          dayCount++;
        }
      }
      rows.add(TableRow(children: week));
      if (dayCount > daysInMonth) break;
    }
    return Table(children: rows);
  }

  Widget _buildDateGroupedSummary() {
    final Map<String, List<TimeOfDay>> grouped = {};
    for (var slot in timeSlots) {
      slot.selectedDates.forEach((dateStr, selected) {
        if (selected) {
          if (!grouped.containsKey(dateStr)) grouped[dateStr] = [];
          grouped[dateStr]!.add(slot.time);
        }
      });
    }
    final sortedDates = grouped.keys.toList()..sort();
    if (sortedDates.isEmpty)
      return Center(
        child: Text('No dates scheduled', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      );
    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, i) {
        final dateStr = sortedDates[i];
        final times = grouped[dateStr]!..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
        final dt = DateTime.parse(dateStr);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('EEE, d MMM').format(dt),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                    ),
                  ),
                  _cardActionBtn(
                    icon: Icons.delete_sweep_rounded,
                    color: Colors.redAccent,
                    onTap: () => _deleteEntireDate(dateStr),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: times
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.format(context),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteEntireDate(String dateStr) async {
    final readableDate = DateFormat('EEE, d MMM').format(DateTime.parse(dateStr));
    final confirmed = await showConfirmDialog(
      context,
      'Remove all slots for $readableDate?',
    );
    if (!confirmed) return;

    setState(() {
      for (final slot in timeSlots) {
        slot.selectedDates.remove(dateStr);
      }
    });
  }

  void _openGenerator() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) => Center(
        child: SingleChildScrollView(
          child: CardContainer(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
              child: WeeklySlotGenerator(initInterval: convertToMinutes(widget.serviceTiming)),
            ),
          ),
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        for (var iso in result) {
          final dt = DateTime.parse(iso);
          final time = TimeOfDay(hour: dt.hour, minute: dt.minute);
          final dateKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          var existing = timeSlots.firstWhere(
            (t) => t.time.hour == time.hour && t.time.minute == time.minute,
            orElse: () {
              final n = TimeSlotDates(time: time, selectedDates: {});
              timeSlots.add(n);
              return n;
            },
          );
          existing.selectedDates[dateKey] = true;
        }
        timeSlots.sort((a, b) => (a.time.hour * 60 + a.time.minute).compareTo(b.time.hour * 60 + b.time.minute));
      });
    }
  }

  int convertToMinutes(String input) {
    try {
      input = input.toLowerCase().trim();
      final match = RegExp(r'^(\d+)\s*(minute|minutes|hour|hours)$').firstMatch(input);
      if (match != null) {
        final val = int.parse(match.group(1)!);
        return match.group(2)!.startsWith('hour') ? val * 60 : val;
      }
    } catch (_) {}
    return 30;
  }
}

class _ApplyToServicesDialog extends StatefulWidget {
  final List<sb_model.Data> services;
  final Map<String, bool> selectedMap;
  final int slotCount;
  const _ApplyToServicesDialog({required this.services, required this.selectedMap, required this.slotCount});
  @override
  State<_ApplyToServicesDialog> createState() => _ApplyToServicesDialogState();
}

class _ApplyToServicesDialogState extends State<_ApplyToServicesDialog> {
  bool get allSelected => widget.services.every((s) => widget.selectedMap[s.serviceBranchId] == true);

  void _toggleAll(bool? val) {
    setState(() {
      for (var s in widget.services) {
        widget.selectedMap[s.serviceBranchId!] = val ?? false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.sync_rounded, color: Color(0xFF6366F1), size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sync Configuration', style: AppTypography.displayMedium(context)),
                      const SizedBox(height: 4),
                      Text(
                        'Push ${widget.slotCount} slots to multiple services',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Critical Sync Warnings',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• This action will OVERRIDE all existing timing for the selected services, even if they have different slot intervals.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9A3412), height: 1.4),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Safety: Bookings will still be blocked if the same practitioner (Doctor Type) is already scheduled during these times.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9A3412), height: 1.4),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Pruning: We automatically remove all past dates to optimize system performance and storage.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9A3412), height: 1.4, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: allSelected,
                    activeColor: secondaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: _toggleAll,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select All Services',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.services.where((s) => widget.selectedMap[s.serviceBranchId] == true).length} selected',
                    style: TextStyle(fontSize: 12, color: secondaryColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ACTIVE SERVICES IN BRANCH',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF), letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final s = widget.services[i];
                  final isSelected = widget.selectedMap[s.serviceBranchId] == true;
                  return InkWell(
                    onTap: () => setState(() => widget.selectedMap[s.serviceBranchId!] = !isSelected),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? secondaryColor.withAlpha(5) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? secondaryColor.withAlpha(100) : const Color(0xFFE5E7EB),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? secondaryColor.withAlpha(20) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.medical_services_outlined,
                              size: 16,
                              color: isSelected ? secondaryColor : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.serviceName ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF111827) : const Color(0xFF4B5563),
                                  ),
                                ),
                                if (s.serviceTime != null || s.doctorType != null)
                                  Text(
                                    '${s.serviceTime ?? '—'} • ${doctorType(s.doctorType)}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            activeColor: secondaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (v) => setState(() => widget.selectedMap[s.serviceBranchId!] = v!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
