import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class WeeklySlotGenerator extends StatefulWidget {
  final int? initInterval;
  const WeeklySlotGenerator({super.key, this.initInterval});

  @override
  State<WeeklySlotGenerator> createState() => _WeeklySlotGeneratorState();
}

class _WeeklySlotGeneratorState extends State<WeeklySlotGenerator> {
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  late final List<DateTime> months;
  late DateTime selectedMonth;
  int interval = 30;
  final Map<String, bool> selectedDays = {};
  final Map<String, List<TimeRange>> timeRanges = {};
  StreamController<DateTime> rebuild = StreamController.broadcast();

  String? copiedFromDay;
  bool isWeekdayMasterMode = true;
  bool hasMasterBreak = false;

  TimeOfDay weekdayMasterStart = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay weekdayMasterEnd = const TimeOfDay(hour: 21, minute: 0);
  List<TimeRange> weekdayBreaks = [
    TimeRange(start: const TimeOfDay(hour: 13, minute: 0), end: const TimeOfDay(hour: 14, minute: 0)),
  ];

  TimeOfDay weekendMasterStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay weekendMasterEnd = const TimeOfDay(hour: 20, minute: 0);
  List<TimeRange> weekendBreaks = [
    TimeRange(start: const TimeOfDay(hour: 13, minute: 0), end: const TimeOfDay(hour: 14, minute: 0)),
  ];

  TimeOfDay get masterStart => isWeekdayMasterMode ? weekdayMasterStart : weekendMasterStart;
  TimeOfDay get masterEnd => isWeekdayMasterMode ? weekdayMasterEnd : weekendMasterEnd;
  List<TimeRange> get masterBreaks => isWeekdayMasterMode ? weekdayBreaks : weekendBreaks;

  @override
  void initState() {
    super.initState();
    interval = widget.initInterval ?? 30;
    final now = DateTime.now();
    months = List.generate(4, (i) => DateTime(now.year, now.month + i));
    selectedMonth = months.first;
    for (var day in days) {
      selectedDays[day] = false;
      timeRanges[day] = [];
    }
  }

  // ─── Bulk Select Actions ──────────────────────────────────────────────────
  void _selectAll(bool val) {
    setState(() {
      for (var day in days) {
        selectedDays[day] = val;
      }
    });
    rebuild.add(DateTime.now());
  }

  void _selectWeekdays() {
    setState(() {
      isWeekdayMasterMode = true;
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
      for (var day in days) {
        selectedDays[day] = weekdays.contains(day);
      }
    });
    rebuild.add(DateTime.now());
  }

  void _selectWeekends() {
    setState(() {
      isWeekdayMasterMode = false;
      final weekends = ['Sat', 'Sun'];
      for (var day in days) {
        selectedDays[day] = weekends.contains(day);
      }
    });
    rebuild.add(DateTime.now());
  }

  void _syncMasterToSelected() {
    final targetCategory = isWeekdayMasterMode ? 'Weekdays' : 'Weekends';
    final masterDays = isWeekdayMasterMode ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'] : ['Sat', 'Sun'];

    final targets = masterDays.where((d) => selectedDays[d] == true).toList();

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No $targetCategory are selected to sync.')));
      return;
    }

    // Validation
    if (hasMasterBreak) {
      if (masterBreaks.isEmpty) {
        showDialogError(context, 'Please add at least one break or disable break mode.');
        return;
      }
      for (var b in masterBreaks) {
        if (!_isBefore(masterStart, b.start) || !_isBefore(b.end, masterEnd)) {
          showDialogError(context, 'All breaks must be WITHIN working hours.');
          return;
        }
        if (!_isBefore(b.start, b.end)) {
          showDialogError(context, 'Break Start must be BEFORE Break End.');
          return;
        }
      }
    } else {
      if (!_isBefore(masterStart, masterEnd)) {
        showDialogError(context, 'Start must be BEFORE End.');
        return;
      }
    }

    setState(() {
      final List<TimeRange> sortedBreaks = List.from(masterBreaks)
        ..sort((a, b) => (a.start.hour * 60 + a.start.minute).compareTo(b.start.hour * 60 + b.start.minute));

      final segments = _getSegments(masterStart, masterEnd, hasMasterBreak ? sortedBreaks : []);

      for (var day in targets) {
        timeRanges[day] = List.from(segments);
      }
    });

    rebuild.add(DateTime.now());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Master timing pushed to selected $targetCategory.'), backgroundColor: secondaryColor),
    );
  }

  List<TimeRange> _getSegments(TimeOfDay start, TimeOfDay end, List<TimeRange> breaks) {
    if (breaks.isEmpty) return [TimeRange(start: start, end: end)];

    List<TimeRange> segments = [];
    TimeOfDay currentStart = start;

    for (var b in breaks) {
      if (_isBefore(currentStart, b.start)) {
        segments.add(TimeRange(start: currentStart, end: b.start));
      }
      currentStart = b.end;
    }

    if (_isBefore(currentStart, end)) {
      segments.add(TimeRange(start: currentStart, end: end));
    }

    return segments;
  }

  void _clearDay(String day) {
    setState(() {
      timeRanges[day] = [];
    });
    rebuild.add(DateTime.now());
  }

  // ─── Time Picker ───
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

  void _generateSlots() {
    final List<String> slots = [];
    for (var day in days) {
      if (selectedDays[day] == true) {
        final dayIndex = days.indexOf(day) + 1;
        final totalDays = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
        for (int i = 1; i <= totalDays; i++) {
          final date = DateTime(selectedMonth.year, selectedMonth.month, i);
          if (date.weekday == dayIndex) {
            for (final range in timeRanges[day]!) {
              TimeOfDay current = range.start;
              while (_isBefore(current, range.end)) {
                final dt = DateTime(date.year, date.month, date.day, current.hour, current.minute);
                slots.add(DateFormat('yyyy-MM-dd HH:mm:ss').format(dt));
                current = _addInterval(current, interval);
                if (!_isBefore(current, range.end)) break;
              }
            }
          }
        }
      }
    }

    if (slots.isEmpty) {
      showDialogError(
        context,
        'No slots were generated. Please ensure at least one day is selected and has time ranges defined.',
      );
      return;
    }

    Navigator.pop(context, slots);
  }

  Future<void> _saveAllSlotsToPrefs() async {
    final data = {
      for (var day in days)
        if (selectedDays[day] == true)
          day: timeRanges[day]!.map((r) => {'start': _formatTime(r.start), 'end': _formatTime(r.end)}).toList(),
    };
    await prefs.setString('saved_weekly_slots', jsonEncode(data));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Timing template saved.'), backgroundColor: Color(0xFF16A34A)));
  }

  Future<void> _loadAllSlotsFromPrefs() async {
    try {
      final jsonString = prefs.getString('saved_weekly_slots');
      if (jsonString == null || jsonString.trim().isEmpty) {
        showDialogError(context, 'No saved timing template found.');
        return;
      }
      final Map<String, dynamic> data = jsonDecode(jsonString);
      for (var entry in data.entries) {
        selectedDays[entry.key] = true;
        timeRanges[entry.key] = (entry.value as List).map((item) {
          return TimeRange(start: _parseTime(item['start']), end: _parseTime(item['end']));
        }).toList();
      }
      rebuild.add(DateTime.now());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timing template loaded.')));
    } catch (e) {
      debugPrint('Error loading saved slots: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load timing template.')));
    }
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
                  Icon(Icons.auto_awesome_rounded, color: Colors.orange[700], size: 24),
                  const SizedBox(width: 12),
                  Text('Getting Started Guide', style: AppTypography.displayMedium(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Follow these steps to generate a complex schedule in seconds:',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _guideStep(
                1,
                'Configure Month & Interval',
                'Select the target month and the duration of each appointment slot (e.g. 30 mins) to define the base grid.',
              ),
              _guideStep(
                2,
                'Define Master Timing',
                'Set your general working hours and breaks. Use the badge at the top right of the Master Timing box to swap between "WEEKDAY" and "WEEKEND" modes.',
              ),
              _guideStep(
                3,
                'Quick Select Days',
                'Use the "Weekdays" or "Weekends" buttons to quickly highlight the relevant days in the list below.',
              ),
              _guideStep(
                4,
                'Push to Category',
                'Click the "Push to..." button to instantaneously apply your master timings to the currently selected days.',
              ),
              _guideStep(
                5,
                'Template Management',
                'Use the "Save" and "Load" buttons at the top to preserve your recurring schedules for future use across different branches.',
              ),
              _guideStep(
                6,
                'Finalize & Generate',
                'Review each day, make manual adjustments if needed, then click "Generate" at the bottom to build your calendar.',
              ),
              const SizedBox(height: 24),
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

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':').map(int.parse).toList();
    return TimeOfDay(hour: parts[0], minute: parts[1]);
  }

  bool _isBeforeOrEqual(TimeOfDay a, TimeOfDay b) => a.hour < b.hour || (a.hour == b.hour && a.minute <= b.minute);
  bool _isBefore(TimeOfDay a, TimeOfDay b) => a.hour < b.hour || (a.hour == b.hour && a.minute < b.minute);

  TimeOfDay _addInterval(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  void _copySlots(String day) {
    copiedFromDay = day;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied timing from $day')));
  }

  void _pasteSlots(String targetDay) {
    if (copiedFromDay != null && copiedFromDay != targetDay) {
      timeRanges[targetDay] = List.from(timeRanges[copiedFromDay!]!);
      rebuild.add(DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Timing pasted to $targetDay')));
    }
  }

  bool _hasOverlap(String day) {
    final ranges = timeRanges[day]!;
    for (int i = 0; i < ranges.length; i++) {
      for (int j = i + 1; j < ranges.length; j++) {
        if (ranges[i].overlapsWith(ranges[j])) return true;
      }
    }
    return false;
  }

  bool _isValidRange(TimeRange range) => _isBeforeOrEqual(range.start, range.end);

  int get _selectedDayCount => selectedDays.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedDayCount;

    return StreamBuilder(
      stream: rebuild.stream,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: secondaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: secondaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly Slot Generator', style: AppTypography.displayMedium(context)),
                      Text(
                        'Fast-track your schedule by syncing working hours across days.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _templateBtn(
                      icon: Icons.help_outline_rounded,
                      label: 'Help',
                      onTap: () => _showHelpGuide(context),
                      color: Colors.orange[700]!,
                    ),
                    const SizedBox(width: 8),
                    _templateBtn(
                      icon: Icons.save_alt_rounded,
                      label: 'Save',
                      onTap: _saveAllSlotsToPrefs,
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    _templateBtn(
                      icon: Icons.unarchive_rounded,
                      label: 'Load',
                      onTap: _loadAllSlotsFromPrefs,
                      color: Colors.grey[600]!,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Config & Master ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Global Configuration',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _configDropdown<DateTime>(
                                label: 'Target Month',
                                value: selectedMonth,
                                items: months
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(
                                          DateFormat('MMM yyyy').format(m),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  selectedMonth = v!;
                                  rebuild.add(DateTime.now());
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _configDropdown<int>(
                                label: 'Slot Interval',
                                value: interval,
                                items: const [15, 30, 45, 60, 90, 120]
                                    .map(
                                      (i) => DropdownMenuItem(
                                        value: i,
                                        child: Text('$i min', style: const TextStyle(fontSize: 13)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  interval = v!;
                                  rebuild.add(DateTime.now());
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Quick Select Days',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            _quickSelectBtn('All', () => _selectAll(true)),
                            _quickSelectBtn('Weekdays', _selectWeekdays),
                            _quickSelectBtn('Weekends', _selectWeekends),
                            _quickSelectBtn('None', () => _selectAll(false), isClear: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [secondaryColor, secondaryColor.withAlpha(200)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: secondaryColor.withAlpha(60), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Master Timing',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => setState(() => isWeekdayMasterMode = !isWeekdayMasterMode),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isWeekdayMasterMode ? 'WEEKDAY' : 'WEEKEND',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.swap_horiz_rounded, size: 12, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _masterTimeField('Start', masterStart, (v) {
                                setState(() {
                                  if (isWeekdayMasterMode)
                                    weekdayMasterStart = v;
                                  else
                                    weekendMasterStart = v;
                                });
                              }),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _masterTimeField('End', masterEnd, (v) {
                                setState(() {
                                  if (isWeekdayMasterMode)
                                    weekdayMasterEnd = v;
                                  else
                                    weekendMasterEnd = v;
                                });
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: hasMasterBreak,
                                activeColor: Colors.white,
                                checkColor: secondaryColor,
                                side: const BorderSide(color: Colors.white70),
                                onChanged: (v) => setState(() => hasMasterBreak = v!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Include Break Time',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (hasMasterBreak) ...[
                          const SizedBox(height: 8),
                          ...masterBreaks.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final b = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _masterTimeField('Break Start', b.start, (v) => setState(() => b.start = v)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _masterTimeField('Break End', b.end, (v) => setState(() => b.end = v)),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => setState(() => masterBreaks.removeAt(idx)),
                                    child: const Icon(
                                      Icons.remove_circle_outline_rounded,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          TextButton.icon(
                            onPressed: () => setState(
                              () => masterBreaks.add(
                                TimeRange(
                                  start: const TimeOfDay(hour: 13, minute: 0),
                                  end: const TimeOfDay(hour: 14, minute: 0),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 14),
                            label: const Text(
                              'Add Break Interval',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 20)),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _syncMasterToSelected,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: secondaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sync_rounded, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Push to ${isWeekdayMasterMode ? 'Weekdays' : 'Weekends'}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Day Rows ───
            Expanded(
              child: ListView.builder(
                itemCount: days.length,
                itemBuilder: (context, i) {
                  final day = days[i];
                  final isSelected = selectedDays[day] == true;
                  final hasRanges = timeRanges[day]!.isNotEmpty;
                  final hasOverlap = _hasOverlap(day);
                  final hasInvalidRange = timeRanges[day]!.any((r) => !_isValidRange(r));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFFF9FAFB).withAlpha(150),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? secondaryColor.withAlpha(100) : const Color(0xFFE5E7EB),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            selectedDays[day] = !isSelected;
                            rebuild.add(DateTime.now());
                          },
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: isSelected,
                                    activeColor: secondaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) {
                                      selectedDays[day] = val!;
                                      rebuild.add(DateTime.now());
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  fullDays[i],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isSelected ? const Color(0xFF111827) : Colors.grey[400],
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected) ...[
                                  if (hasRanges)
                                    _dayActionBtn(
                                      icon: Icons.cleaning_services_rounded,
                                      tooltip: 'Clear All',
                                      onTap: () => _clearDay(day),
                                      color: Colors.redAccent,
                                    ),
                                  _dayActionBtn(
                                    icon: copiedFromDay == day ? Icons.check_circle_rounded : Icons.copy_rounded,
                                    tooltip: 'Copy timing',
                                    onTap: () => _copySlots(day),
                                    color: copiedFromDay == day ? const Color(0xFF16A34A) : Colors.grey[500]!,
                                  ),
                                  _dayActionBtn(
                                    icon: Icons.paste_rounded,
                                    tooltip: 'Paste timing',
                                    onTap: copiedFromDay != null && copiedFromDay != day
                                        ? () => _pasteSlots(day)
                                        : null,
                                    color: const Color(0xFF6366F1),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!hasRanges)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        'No time ranges defined yet.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[400],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: timeRanges[day]!.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final range = entry.value;
                                      final itemOverlap = timeRanges[day]!.any(
                                        (other) => other != range && other.overlapsWith(range),
                                      );
                                      final itemInvalid = itemOverlap || !_isValidRange(range);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: itemInvalid ? Colors.red.withAlpha(10) : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: itemInvalid ? Colors.red.shade200 : Colors.transparent,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _compactTimeChip('Start', range.start, () async {
                                              final picked = await _showTimePicker(range.start);
                                              if (picked != null) {
                                                range.start = picked;
                                                rebuild.add(DateTime.now());
                                              }
                                            }),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              child: Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 14,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                            _compactTimeChip('End', range.end, () async {
                                              final picked = await _showTimePicker(range.end);
                                              if (picked != null) {
                                                range.end = picked;
                                                rebuild.add(DateTime.now());
                                              }
                                            }),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () async {
                                                if (await showConfirmDialog(context, 'Remove this range for $day?')) {
                                                  timeRanges[day]!.removeAt(index);
                                                  rebuild.add(DateTime.now());
                                                }
                                              },
                                              child: const Icon(
                                                Icons.cancel_rounded,
                                                size: 18,
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () {
                                    timeRanges[day]!.add(
                                      TimeRange(
                                        start: const TimeOfDay(hour: 9, minute: 0),
                                        end: const TimeOfDay(hour: 17, minute: 0),
                                      ),
                                    );
                                    rebuild.add(DateTime.now());
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text(
                                    'Add Range',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: secondaryColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    backgroundColor: secondaryColor.withAlpha(15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                if (hasOverlap)
                                  _miniWarning(Icons.warning_amber_rounded, 'Overlapping ranges', Colors.orange),
                                if (hasInvalidRange)
                                  _miniWarning(Icons.error_outline_rounded, 'Start must be before End', Colors.red),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCount == 0
                            ? 'No days selected'
                            : '$selectedCount day${selectedCount == 1 ? '' : 's'} to generate',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Text(
                        'Total working days will be calculated for the target month.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 48,
                    child: Button(selectedCount == 0 ? null : _generateSlots, actionText: 'Generate All Slots'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Helpers ───
  Widget _configDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827), fontWeight: FontWeight.w600),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickSelectBtn(String label, VoidCallback onTap, {bool isClear = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isClear ? Colors.red.withAlpha(10) : const Color(0xFF6366F1).withAlpha(10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isClear ? Colors.red.withAlpha(100) : const Color(0xFF6366F1).withAlpha(100)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isClear ? Colors.red : const Color(0xFF6366F1),
          ),
        ),
      ),
    );
  }

  Widget _masterTimeField(String label, TimeOfDay time, Function(TimeOfDay) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await _showTimePicker(time);
            if (picked != null) onPicked(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time.format(context),
                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayActionBtn({required IconData icon, required String tooltip, required Color color, VoidCallback? onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      color: onTap != null ? color : Colors.grey[300],
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _compactTimeChip(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 8, color: Colors.grey[500], fontWeight: FontWeight.bold),
          ),
          Text(time.format(context), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _templateBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(100)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniWarning(IconData icon, String msg, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            msg,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class TimeRange {
  TimeOfDay start;
  TimeOfDay end;
  TimeRange({required this.start, required this.end});

  bool overlapsWith(TimeRange other) {
    final s1 = start.hour * 60 + start.minute;
    final e1 = end.hour * 60 + end.minute;
    final s2 = other.start.hour * 60 + other.start.minute;
    final e2 = other.end.hour * 60 + other.end.minute;
    return s1 < e2 && s2 < e1;
  }
}
