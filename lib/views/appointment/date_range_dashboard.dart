import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRange {
  final String label;
  final DateTime? start;
  final DateTime? end;

  DateRange({required this.label, this.start, this.end});
}

class DateFilterDropdown extends StatefulWidget {
  final Function(DateRange) onSelected;

  const DateFilterDropdown({super.key, required this.onSelected});

  @override
  State<DateFilterDropdown> createState() => _DateFilterDropdownState();
}

class _DateFilterDropdownState extends State<DateFilterDropdown> {
  late DateRange _selected;

  @override
  void initState() {
    super.initState();
    _selected = _defaultThisMonth();
  }

  DateRange _defaultThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return DateRange(
      label: 'This month (${DateFormat('MMMM yyyy').format(now)})',
      start: startOfMonth,
      end: endOfMonth,
    );
  }

  List<DateRange> _generateDateRanges() {
    final now = DateTime.now();

    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);

    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);

    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final endOfNextMonth = DateTime(now.year, now.month + 2, 0);

    return [
      DateRange(
        label: 'Today (${DateFormat('dd MMMM yyyy').format(now)})',
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
      DateRange(
        label:
            'This week (${DateFormat('dd MMM').format(startOfWeek)} - ${DateFormat('dd MMM yyyy').format(endOfWeek)})',
        start: startOfWeek,
        end: endOfWeek,
      ),
      DateRange(
        label: 'Last month (${DateFormat('MMMM yyyy').format(lastMonth)})',
        start: lastMonth,
        end: endOfLastMonth,
      ),
      DateRange(label: 'This month (${DateFormat('MMMM yyyy').format(now)})', start: startOfMonth, end: endOfMonth),
      DateRange(
        label: 'Next month (${DateFormat('MMMM yyyy').format(nextMonth)})',
        start: nextMonth,
        end: endOfNextMonth,
      ),
      DateRange(label: 'This year (${now.year})', start: startOfYear, end: endOfYear),
      DateRange(label: 'All time', start: null, end: null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final options = _generateDateRanges();

    return PopupMenuButton<DateRange>(
      color: Colors.white,
      onSelected: (range) {
        setState(() => _selected = range);
        widget.onSelected(range);
      },
      itemBuilder: (context) {
        return options.map((range) => PopupMenuItem<DateRange>(value: range, child: Text(range.label))).toList();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selected.label.split('(')[0].trim(), // "This month", etc.
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }
}
