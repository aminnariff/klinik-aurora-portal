import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class TimeSlotDates {
  final TimeOfDay time;
  final Map<String, bool> selectedDates;

  TimeSlotDates({required this.time, required this.selectedDates});
}

class MultiTimeCalendarPage extends StatefulWidget {
  final String serviceBranchId;
  final String? serviceBranchAvailableDatetimeId;
  final int startMonth;
  final int year;
  final int totalMonths;
  final List<String>? initialDateTimes;

  const MultiTimeCalendarPage({
    super.key,
    required this.serviceBranchId,
    this.serviceBranchAvailableDatetimeId,
    required this.startMonth,
    required this.year,
    this.totalMonths = 2,
    this.initialDateTimes,
  });

  @override
  State<MultiTimeCalendarPage> createState() => _MultiTimeCalendarPageState();
}

class _MultiTimeCalendarPageState extends State<MultiTimeCalendarPage> {
  final List<TimeSlotDates> timeSlots = [];
  final DateTime today = DateTime.now();
  int currentMonthIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialDateTimes != null) {
      _loadInitialSelections(widget.initialDateTimes!);
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
          // Invalid format, skip
        }
      }
      setState(() {
        timeSlots.addAll(timeMap.values);
      });
    });
  }

  void _addTimeSlot() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        timeSlots.add(TimeSlotDates(time: picked, selectedDates: {}));
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

  List<String> filterCurrentPrevAndFutureMonths(List<String> isoDates, {DateTime? nowOverride}) {
    final nowLocal = (nowOverride ?? DateTime.now()).toLocal();
    final prevMonthStart = DateTime(nowLocal.year, nowLocal.month - 1, 1);

    return isoDates.where((s) {
      try {
        final dtLocal = DateTime.parse(s).toLocal();
        return !dtLocal.isBefore(prevMonthStart);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    int displayMonth = widget.startMonth + currentMonthIndex;
    int displayYear = widget.year + ((displayMonth - 1) ~/ 12);
    displayMonth = ((displayMonth - 1) % 12) + 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: currentMonthIndex > 0 ? () => setState(() => currentMonthIndex--) : null,
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(DateTime(displayYear, displayMonth)),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: currentMonthIndex < widget.totalMonths - 1
                          ? () => setState(() => currentMonthIndex++)
                          : null,
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: timeSlots.length,
                    itemBuilder: (context, index) {
                      final slot = timeSlots[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${index + 1}.'),
                          Card(
                            margin: const EdgeInsets.all(12),
                            color: Colors.grey.shade100,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Time: ${slot.time.format(context)}",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => setState(() => timeSlots.removeAt(index)),
                                      ),
                                    ],
                                  ),
                                  _buildCalendar(slot.selectedDates, displayMonth, displayYear),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Button(() async {
                      if (await showConfirmDialog(
                        context,
                        'Are you sure you want to ${widget.serviceBranchAvailableDatetimeId == null ? 'create' : 'update'} the available time slots?',
                      )) {
                        if (widget.serviceBranchAvailableDatetimeId == null) {
                          ServiceBranchAvailableDtController.create(
                            context,
                            widget.serviceBranchId,
                            _getAllDateTimeValues(),
                          ).then((value) {
                            if (responseCode(value.code)) {
                              showDialogSuccess(context, 'Successfully Created the Available Appointment');
                            } else {
                              showDialogError(
                                context,
                                value.message ??
                                    'Unable to create the available appointment slots. Please contact support if you still encounter this issue.',
                              );
                            }
                          });
                        } else {
                          List<String> updatedSlots = _getAllDateTimeValues();
                          updatedSlots = filterCurrentPrevAndFutureMonths(updatedSlots);
                          ServiceBranchAvailableDtController.update(
                            context,
                            widget.serviceBranchAvailableDatetimeId ?? '',
                            widget.serviceBranchId,
                            updatedSlots,
                          ).then((value) {
                            if (responseCode(value.code)) {
                              showDialogSuccess(context, 'Successfully Updated the Available Appointment');
                            } else {
                              showDialogError(
                                context,
                                value.message ?? 'Unable to update the available appointment slots',
                              );
                            }
                          });
                        }
                      }
                    }, actionText: widget.serviceBranchAvailableDatetimeId == null ? 'Create' : 'Update'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summary', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1)),
                  const SizedBox(height: 12),
                  Expanded(child: _buildDateGroupedSummary()),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        onPressed: _addTimeSlot,
        label: const Text("Add Time"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar(Map<String, bool> selectedDates, int displayMonth, int displayYear) {
    DateTime firstDay = DateTime(displayYear, displayMonth, 1);
    int daysInMonth = DateTime(displayYear, displayMonth + 1, 0).day;
    int startWeekday = firstDay.weekday % 7;

    List<TableRow> rows = [];
    List<String> dayLabels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    rows.add(
      TableRow(
        children: List.generate(
          7,
          (index) => Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                dayLabels[index],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: (index == 0 || index == 6) ? Colors.grey : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    int dayCounter = 1;
    for (int i = 0; i < 6; i++) {
      List<Widget> weekRow = [];
      for (int j = 0; j < 7; j++) {
        if ((i == 0 && j < startWeekday) || dayCounter > daysInMonth) {
          weekRow.add(Container(height: 40));
        } else {
          final key =
              '$displayYear-${displayMonth.toString().padLeft(2, '0')}-${dayCounter.toString().padLeft(2, '0')}';
          final isSelected = selectedDates[key] == true;
          final isToday = today.year == displayYear && today.month == displayMonth && today.day == dayCounter;
          final isPast = DateTime(
            displayYear,
            displayMonth,
            dayCounter,
          ).isBefore(DateTime(today.year, today.month, today.day));
          final textColor = isPast
              ? Colors.grey.shade400
              : (j == 0 || j == 6)
              ? Colors.grey
              : Colors.black;

          weekRow.add(
            GestureDetector(
              onTap: isPast
                  ? null
                  : () {
                      setState(() {
                        selectedDates[key] = !isSelected;
                      });
                    },
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday ? Colors.orange.shade100 : null,
                  border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dayCounter',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              ),
            ),
          );
          dayCounter++;
        }
      }
      rows.add(TableRow(children: weekRow));
      if (dayCounter > daysInMonth) break;
    }

    return Table(defaultColumnWidth: const FixedColumnWidth(42), children: rows);
  }

  Widget _buildDateGroupedSummary() {
    final Map<DateTime, List<TimeOfDay>> dateToTimes = {};

    // Helper: allow only current month + next 2 months
    bool isInAllowedWindow(DateTime d) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month); // 1st of this month
      final end = DateTime(start.year, start.month + 3); // exclusive upper bound
      final day = DateTime(d.year, d.month, d.day);
      return day.isAtSameMomentAs(start) || (day.isAfter(start) && day.isBefore(end));
    }

    // Step 1: Group selected time slots by exact date
    for (final slot in timeSlots) {
      slot.selectedDates.forEach((dateStr, selected) {
        if (selected) {
          final parts = dateStr.split('-').map(int.parse).toList();
          final date = DateTime(parts[0], parts[1], parts[2]);
          if (isInAllowedWindow(date)) {
            dateToTimes.putIfAbsent(date, () => []).add(slot.time);
          }
        }
      });
    }

    if (dateToTimes.isEmpty) {
      return const Text('No appointment slots selected.');
    }

    // Step 2: Group by (year, month) for only-allowed dates
    final Map<String, List<DateTime>> monthToDates = {};
    for (final date in dateToTimes.keys) {
      final monthKey = DateFormat('MMMM yyyy').format(date);
      monthToDates.putIfAbsent(monthKey, () => []).add(date);
    }

    final sortedMonthKeys = monthToDates.keys.toList()
      ..sort((a, b) {
        final aDate = DateFormat('MMMM yyyy').parse(a);
        final bDate = DateFormat('MMMM yyyy').parse(b);
        return aDate.compareTo(bDate);
      });

    return ListView.builder(
      itemCount: sortedMonthKeys.length,
      itemBuilder: (context, monthIndex) {
        final monthKey = sortedMonthKeys[monthIndex];
        final dates = monthToDates[monthKey]!..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text('📆 $monthKey', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...dates.map((date) {
              final times = dateToTimes[date]!
                ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.grey.shade100,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📅 ${DateFormat('EEE, d MMM yyyy').format(date)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: times
                            .map(
                              (time) => Chip(label: Text(time.format(context), style: const TextStyle(fontSize: 12))),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
