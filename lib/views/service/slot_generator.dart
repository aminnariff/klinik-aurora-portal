import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late final List<DateTime> months;
  late DateTime selectedMonth;
  int interval = 30;
  final Map<String, bool> selectedDays = {};
  final Map<String, List<TimeRange>> timeRanges = {};
  StreamController<DateTime> rebuild = StreamController.broadcast();

  String? copiedFromDay;

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
              while (_isBeforeOrEqual(current, range.end)) {
                final dt = DateTime(date.year, date.month, date.day, current.hour, current.minute);
                slots.add(DateFormat('yyyy-MM-dd HH:mm:ss').format(dt));
                current = _addInterval(current, interval);
                if (!_isBeforeOrEqual(current, range.end)) break;
              }
            }
          }
        }
      }
    }
    debugPrint(slots.join(',\n'));
    Navigator.pop(context, slots);
    // showDialog(
    //   context: context,
    //   builder: (_) => AlertDialog(
    //     title: const Text('Generated Slots'),
    //     content: SingleChildScrollView(child: Text(slots.join(',\n'))),
    //     actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    //   ),
    // );
  }

  Future<void> _saveAllSlotsToPrefs() async {
    final data = {
      for (var day in days)
        if (selectedDays[day] == true)
          day: timeRanges[day]!.map((r) => {'start': _formatTime(r.start), 'end': _formatTime(r.end)}).toList(),
    };
    await prefs.setString('saved_weekly_slots', jsonEncode(data));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved all day slots to memory')));
  }

  Future<void> _loadAllSlotsFromPrefs() async {
    try {
      final jsonString = prefs.getString('saved_weekly_slots');

      if (jsonString == null || jsonString.trim().isEmpty) {
        showDialogError(context, 'No saved slots found.');
        debugPrint('No saved slots found.');
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pasted saved slots to all days')));
    } catch (e) {
      debugPrint('Error loading saved slots: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load saved slots')));
    }
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':').map(int.parse).toList();
    return TimeOfDay(hour: parts[0], minute: parts[1]);
  }

  bool _isBeforeOrEqual(TimeOfDay a, TimeOfDay b) {
    return a.hour < b.hour || (a.hour == b.hour && a.minute <= b.minute);
  }

  TimeOfDay _addInterval(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  void _copySlots(String day) {
    copiedFromDay = day;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied from $day')));
  }

  void _pasteSlots(String targetDay) {
    if (copiedFromDay != null && copiedFromDay != targetDay) {
      timeRanges[targetDay] = List.from(timeRanges[copiedFromDay!]!);
      rebuild.add(DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pasted to $targetDay')));
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

  bool _isValidRange(TimeRange range) {
    return _isBeforeOrEqual(range.start, range.end);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: rebuild.stream,
      builder: (context, asyncSnapshot) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Weekly Slot Generator', style: AppTypography.displayMedium(context)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text("Select Month: "),
                  const SizedBox(width: 10),
                  DropdownButton<DateTime>(
                    value: selectedMonth,
                    onChanged: (value) {
                      selectedMonth = value!;
                      rebuild.add(DateTime.now());
                    },
                    items: months
                        .map((m) => DropdownMenuItem(value: m, child: Text(DateFormat('MMMM yyyy').format(m))))
                        .toList(),
                  ),
                  const SizedBox(width: 30),
                  const Text("Interval: "),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: interval,
                    onChanged: (value) {
                      interval = value!;
                      rebuild.add(DateTime.now());
                    },
                    items: const [
                      15,
                      30,
                      45,
                      60,
                      75,
                      90,
                      120,
                    ].map((i) => DropdownMenuItem(value: i, child: Text('$i mins'))).toList(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _saveAllSlotsToPrefs,
                        child: Row(children: [Text('Save All Timing')]),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _loadAllSlotsFromPrefs,
                        child: Row(children: [Text('Paste Saved Timing')]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: days.map((day) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: selectedDays[day],
                              onChanged: (val) {
                                selectedDays[day] = val!;
                                rebuild.add(DateTime.now());
                              },
                            ),
                            Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(
                              onPressed: selectedDays[day] == true ? () => _copySlots(day) : null,
                              tooltip: 'copy $day timing(s)',
                              icon: const Icon(Icons.copy, size: 20),
                            ),
                            IconButton(
                              onPressed: selectedDays[day] == true ? () => _pasteSlots(day) : null,
                              tooltip: 'paste copied timing(s)',
                              icon: const Icon(Icons.paste, size: 20),
                            ),
                          ],
                        ),
                        if (selectedDays[day] == true)
                          Column(
                            children: [
                              ...timeRanges[day]!.asMap().entries.map((entry) {
                                int index = entry.key;
                                TimeRange range = entry.value;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: range.start,
                                          );
                                          if (picked != null) {
                                            range.start = picked;
                                            rebuild.add(DateTime.now());
                                          }
                                        },
                                        child: Text('Start: ${range.start.format(context)}'),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () async {
                                          final picked = await showTimePicker(context: context, initialTime: range.end);
                                          if (picked != null) {
                                            range.end = picked;
                                            rebuild.add(DateTime.now());
                                          }
                                        },
                                        child: Text('End: ${range.end.format(context)}'),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'delete timing',
                                      onPressed: () {
                                        timeRanges[day]!.removeAt(index);
                                        rebuild.add(DateTime.now());
                                      },
                                      icon: const Icon(Icons.delete, size: 20),
                                    ),
                                  ],
                                );
                              }),
                              IconButton(
                                onPressed: () {
                                  timeRanges[day]!.add(
                                    TimeRange(
                                      start: const TimeOfDay(hour: 9, minute: 0),
                                      end: const TimeOfDay(hour: 10, minute: 0),
                                    ),
                                  );
                                  rebuild.add(DateTime.now());
                                },
                                icon: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add Range',
                                      style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                                    ),
                                  ],
                                ),
                              ),
                              if (_hasOverlap(day))
                                const Text('❗ Overlapping ranges detected', style: TextStyle(color: Colors.red)),
                              if (timeRanges[day]!.any((r) => !_isValidRange(r)))
                                const Text('❗ Start time must be before end time', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        const Divider(),
                      ],
                    );
                  }).toList(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [Button(_generateSlots, actionText: 'Generate Slots')],
              ),
            ],
          ),
        );
      },
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
