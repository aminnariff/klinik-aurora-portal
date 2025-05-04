import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectionCalendarView extends StatefulWidget {
  final int startMonth;
  final int year;
  final int totalMonths;
  final List<String> initialDateTimes;

  const SelectionCalendarView({
    super.key,
    required this.startMonth,
    required this.year,
    this.totalMonths = 2,
    required this.initialDateTimes,
  });

  @override
  State<SelectionCalendarView> createState() => _SelectionCalendarViewState();
}

class _SelectionCalendarViewState extends State<SelectionCalendarView> {
  final DateTime today = DateTime.now();
  int currentMonthIndex = 0;
  String? selectedDate;
  TimeOfDay? selectedTime;
  final Map<String, List<TimeOfDay>> availableSlots = {};

  @override
  void initState() {
    super.initState();
    _processInitialTimes();
  }

  void _processInitialTimes() {
    for (final iso in widget.initialDateTimes) {
      try {
        final dt = DateTime.parse(iso).toLocal();
        final key = DateFormat('yyyy-MM-dd').format(dt);
        availableSlots.putIfAbsent(key, () => []);
        availableSlots[key]!.add(TimeOfDay(hour: dt.hour, minute: dt.minute));
      } catch (_) {}
    }
  }

  void _onContinue() {
    if (selectedDate != null && selectedTime != null) {
      final parts = selectedDate!.split('-').map(int.parse).toList();
      final dt = DateTime(parts[0], parts[1], parts[2], selectedTime!.hour, selectedTime!.minute);
      final formatted = DateFormat('yyyy-MM-dd HH:mm').format(dt);

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Selected Slot'),
              content: Text(formatted),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int displayMonth = widget.startMonth + currentMonthIndex;
    int displayYear = widget.year + ((displayMonth - 1) ~/ 12);
    displayMonth = ((displayMonth - 1) % 12) + 1;

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
          final date = DateTime(displayYear, displayMonth, dayCounter);
          final key = DateFormat('yyyy-MM-dd').format(date);
          final isToday = today.year == date.year && today.month == date.month && today.day == date.day;
          final isDisabled = !availableSlots.containsKey(key);
          final isSelected = selectedDate == key;

          weekRow.add(
            GestureDetector(
              onTap:
                  isDisabled
                      ? null
                      : () => setState(() {
                        selectedDate = key;
                        selectedTime = null;
                      }),
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected
                          ? Colors.blue.shade100
                          : isToday
                          ? Colors.orange.shade100
                          : null,
                  border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dayCounter',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDisabled
                            ? Colors.grey.shade400
                            : (j == 0 || j == 6)
                            ? Colors.black
                            : Colors.black,
                    fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
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
              onPressed: currentMonthIndex < widget.totalMonths - 1 ? () => setState(() => currentMonthIndex++) : null,
            ),
          ],
        ),
        Table(defaultColumnWidth: const FixedColumnWidth(42), children: rows),
        const SizedBox(height: 16),
        if (selectedDate != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE, d MMM yyyy').format(DateTime.parse(selectedDate!)),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                availableSlots[selectedDate]!
                    .map(
                      (t) => OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selectedTime == t ? Colors.blue.shade50 : null,
                        ),
                        onPressed: () => setState(() => selectedTime = t),
                        child: Text(t.format(context)),
                      ),
                    )
                    .toList(),
          ),
        ],
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: selectedDate != null && selectedTime != null ? _onContinue : null,
            child: const Text("Continue"),
          ),
        ),
      ],
    );
  }
}
