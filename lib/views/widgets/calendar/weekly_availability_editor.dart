import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';

/// Owns the weekly pattern state (selected days + per-day time ranges) so
/// hosts can read/set it programmatically while [WeeklyAvailabilityEditor]
/// renders and edits it.
///
/// Hosts own the lifecycle: create the controller, pass it to the editor,
/// and call [dispose] when done — the editor never disposes it.
class WeeklyAvailabilityEditorController extends ChangeNotifier {
  final Map<String, bool> selectedDays = {for (final d in weekDayKeys) d: false};
  final Map<String, List<TimeRange>> timeRanges = {for (final d in weekDayKeys) d: []};

  WeeklyPattern get pattern => WeeklyPattern(dayRanges: {
        for (final d in weekDayKeys)
          if (selectedDays[d] == true && timeRanges[d]!.isNotEmpty) d: List.of(timeRanges[d]!),
      });

  void setPattern(WeeklyPattern pattern) {
    for (final d in weekDayKeys) {
      final ranges = pattern.dayRanges[d] ?? [];
      selectedDays[d] = ranges.isNotEmpty;
      timeRanges[d] = List.of(ranges);
    }
    notifyListeners();
  }

  int get selectedDayCount => selectedDays.values.where((v) => v).length;

  bool get isValid {
    if (selectedDayCount == 0) return false;
    for (final d in weekDayKeys) {
      if (selectedDays[d] != true) continue;
      final ranges = timeRanges[d]!;
      if (ranges.isEmpty) return false;
      for (var i = 0; i < ranges.length; i++) {
        final r = ranges[i];
        final startM = r.start.hour * 60 + r.start.minute;
        final endM = r.end.hour * 60 + r.end.minute;
        if (startM >= endM) return false; // zero-width ranges generate no slots
        for (var j = i + 1; j < ranges.length; j++) {
          if (r.overlapsWith(ranges[j])) return false;
        }
      }
    }
    return true;
  }

  void refresh() => notifyListeners();
}

/// The weekly-pattern editing UI extracted from WeeklySlotGenerator:
/// quick day selection, master timing push, and per-day time-range rows.
class WeeklyAvailabilityEditor extends StatefulWidget {
  final WeeklyAvailabilityEditorController controller;

  /// When true the day list expands to fill remaining space and scrolls
  /// itself; when false it shrink-wraps and the host provides scrolling.
  final bool expandDayList;

  const WeeklyAvailabilityEditor({super.key, required this.controller, this.expandDayList = true});

  @override
  State<WeeklyAvailabilityEditor> createState() => _WeeklyAvailabilityEditorState();
}

class _WeeklyAvailabilityEditorState extends State<WeeklyAvailabilityEditor> {
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

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

  Map<String, bool> get selectedDays => widget.controller.selectedDays;
  Map<String, List<TimeRange>> get timeRanges => widget.controller.timeRanges;

  void _notify() {
    setState(() {});
    widget.controller.refresh();
  }

  // ─── Bulk Select Actions ──────────────────────────────────────────────────
  void _selectAll(bool val) {
    setState(() {
      for (var day in days) {
        selectedDays[day] = val;
      }
    });
    _notify();
  }

  void _selectWeekdays() {
    setState(() {
      isWeekdayMasterMode = true;
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
      for (var day in days) {
        selectedDays[day] = weekdays.contains(day);
      }
    });
    _notify();
  }

  void _selectWeekends() {
    setState(() {
      isWeekdayMasterMode = false;
      final weekends = ['Sat', 'Sun'];
      for (var day in days) {
        selectedDays[day] = weekends.contains(day);
      }
    });
    _notify();
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

    _notify();
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
    _notify();
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

  bool _isBefore(TimeOfDay a, TimeOfDay b) => a.hour < b.hour || (a.hour == b.hour && a.minute < b.minute);

  void _copySlots(String day) {
    copiedFromDay = day;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied timing from $day')));
  }

  void _pasteSlots(String targetDay) {
    if (copiedFromDay != null && copiedFromDay != targetDay) {
      timeRanges[targetDay] = List.from(timeRanges[copiedFromDay!]!);
      _notify();
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

  bool _isValidRange(TimeRange range) => _isBefore(range.start, range.end);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final dayList = ListView.builder(
          shrinkWrap: !widget.expandDayList,
          physics: widget.expandDayList ? null : const NeverScrollableScrollPhysics(),
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
                      _notify();
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
                                _notify();
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
                                          _notify();
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
                                          _notify();
                                        }
                                      }),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () async {
                                          if (await showConfirmDialog(context, 'Remove this range for $day?')) {
                                            timeRanges[day]!.removeAt(index);
                                            _notify();
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
                              _notify();
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
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Quick Select & Master ───
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
                                  if (isWeekdayMasterMode) {
                                    weekdayMasterStart = v;
                                  } else {
                                    weekendMasterStart = v;
                                  }
                                });
                              }),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _masterTimeField('End', masterEnd, (v) {
                                setState(() {
                                  if (isWeekdayMasterMode) {
                                    weekdayMasterEnd = v;
                                  } else {
                                    weekendMasterEnd = v;
                                  }
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
            if (widget.expandDayList) Expanded(child: dayList) else dayList,
          ],
        );
      },
    );
  }

  // ─── Helpers ───
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
