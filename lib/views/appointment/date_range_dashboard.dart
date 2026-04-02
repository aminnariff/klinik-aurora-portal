import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRange {
  final String label;
  final String shortLabel;
  final DateTime? start;
  final DateTime? end;

  DateRange({required this.label, required this.shortLabel, this.start, this.end});
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
    return DateRange(
      label: 'This month (${DateFormat('MMMM yyyy').format(now)})',
      shortLabel: 'This Month',
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
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
        label: 'Today (${DateFormat('dd MMM yyyy').format(now)})',
        shortLabel: 'Today',
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
      DateRange(
        label: 'This week (${DateFormat('dd MMM').format(startOfWeek)} – ${DateFormat('dd MMM').format(endOfWeek)})',
        shortLabel: 'This Week',
        start: startOfWeek,
        end: endOfWeek,
      ),
      DateRange(
        label: 'Last month (${DateFormat('MMMM yyyy').format(lastMonth)})',
        shortLabel: 'Last Month',
        start: lastMonth,
        end: endOfLastMonth,
      ),
      DateRange(
        label: 'This month (${DateFormat('MMMM yyyy').format(now)})',
        shortLabel: 'This Month',
        start: startOfMonth,
        end: endOfMonth,
      ),
      DateRange(
        label: 'Next month (${DateFormat('MMMM yyyy').format(nextMonth)})',
        shortLabel: 'Next Month',
        start: nextMonth,
        end: endOfNextMonth,
      ),
      DateRange(
        label: 'This year (${now.year})',
        shortLabel: 'This Year',
        start: startOfYear,
        end: endOfYear,
      ),
      DateRange(label: 'All time', shortLabel: 'All Time', start: null, end: null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final options = _generateDateRanges();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((range) {
          final selected = _selected.shortLabel == range.shortLabel;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: range.label,
              child: GestureDetector(
                onTap: () {
                  setState(() => _selected = range);
                  widget.onSelected(range);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFDF6E98) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? const Color(0xFFDF6E98) : const Color(0xFFE5E7EB),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFDF6E98).withAlpha(51),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    range.shortLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
