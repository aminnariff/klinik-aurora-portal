import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectionCalendarDateOnlyView extends StatefulWidget {
  final int startMonth;
  final int year;
  final int totalMonths;
  final List<String> availableDates; // Expect ISO strings: 'yyyy-MM-dd'

  const SelectionCalendarDateOnlyView({
    super.key,
    required this.startMonth,
    required this.year,
    this.totalMonths = 3,
    required this.availableDates,
  });

  @override
  State<SelectionCalendarDateOnlyView> createState() => _SelectionCalendarDateOnlyViewState();
}

class _SelectionCalendarDateOnlyViewState extends State<SelectionCalendarDateOnlyView> {
  final DateTime today = DateTime.now();
  int currentMonthIndex = 0;
  String? selectedDate;
  final Set<String> availableDates = {};

  @override
  void initState() {
    super.initState();
    availableDates.addAll(widget.availableDates.map((e) => DateFormat('yyyy-MM-dd').format(DateTime.parse(e))));
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
          final allowAll = availableDates.isEmpty;
          final isDisabled = !allowAll && !availableDates.contains(key);
          final isSelected = selectedDate == key;

          weekRow.add(
            GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      setState(() {
                        selectedDate = key;
                      });

                      final formatted = DateFormat('dd-MM-yyyy').format(DateTime.parse(key));
                      Navigator.pop(context, formatted);
                    },
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
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
                    color: isDisabled
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
          mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 8),
        if (selectedDate != null)
          Text(
            'Selected: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(selectedDate!))}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
