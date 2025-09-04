import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  final int startMonth;
  final int year;
  final int totalMonths;

  const CalendarPage({super.key, required this.startMonth, required this.year, this.totalMonths = 1});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late int currentMonthIndex;
  Map<String, bool> selectedDates = {}; // key: '2025-05-01'
  final DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();
    currentMonthIndex = 0; // start at first month
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

    // Header with weekend styling
    List<String> dayLabels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    rows.add(
      TableRow(
        children: List.generate(7, (index) {
          return Center(
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
          );
        }),
      ),
    );

    int dayCounter = 1;
    for (int i = 0; i < 6; i++) {
      List<Widget> weekRow = [];
      for (int j = 0; j < 7; j++) {
        if ((i == 0 && j < startWeekday) || dayCounter > daysInMonth) {
          weekRow.add(Container(height: 40));
        } else {
          String key =
              '$displayYear-${displayMonth.toString().padLeft(2, '0')}-${dayCounter.toString().padLeft(2, '0')}';
          bool isSelected = selectedDates[key] == true;

          bool isToday = (today.year == displayYear && today.month == displayMonth && today.day == dayCounter);
          bool isPast = DateTime(
            displayYear,
            displayMonth,
            dayCounter,
          ).isBefore(DateTime(today.year, today.month, today.day));
          final isWeekend = (j == 0 || j == 6);
          Color textColor =
              isPast
                  ? Colors.grey.shade400
                  : isWeekend
                  ? Colors.grey
                  : Colors.black;

          // textColor = (j == 0 || j == 6) ? Colors.grey : Colors.black;

          weekRow.add(
            GestureDetector(
              onTap:
                  isPast
                      ? null
                      : () {
                        setState(() {
                          selectedDates[key] = !isSelected;
                        });
                      },
              child: Container(
                margin: EdgeInsets.all(4),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday ? Colors.blue.shade100 : null,
                  border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dayCounter',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? Colors.blue : textColor,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed:
                    currentMonthIndex > 0
                        ? () {
                          setState(() {
                            currentMonthIndex--;
                          });
                        }
                        : null,
              ),
              Text(
                DateFormat('MMMM yyyy').format(firstDay),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed:
                    currentMonthIndex < widget.totalMonths - 1
                        ? () {
                          setState(() {
                            currentMonthIndex++;
                          });
                        }
                        : null,
              ),
            ],
          ),
          SizedBox(height: 8),
          Table(defaultColumnWidth: FixedColumnWidth(42), children: rows),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              List<String> selected =
                  selectedDates.entries.where((entry) => entry.value).map((entry) => entry.key).toList();

              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: Text('Selected Dates'),
                      content: Text(selected.join(', ')),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
                    ),
              );
            },
            child: Text("Show Selected Dates"),
          ),
        ],
      ),
    );
  }
}
