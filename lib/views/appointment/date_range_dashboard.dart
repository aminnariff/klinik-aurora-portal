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
  static const Color _accent = Color(0xFFDF6E98);

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
    final yesterday = now.subtract(const Duration(days: 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
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
        label: 'Yesterday (${DateFormat('dd MMM yyyy').format(yesterday)})',
        shortLabel: 'Yesterday',
        start: DateTime(yesterday.year, yesterday.month, yesterday.day),
        end: DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
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
        label: 'Next 3 months',
        shortLabel: 'Next 3 Months',
        start: startOfMonth,
        end: DateTime(now.year, now.month + 3, 0),
      ),
      DateRange(label: 'All time', shortLabel: 'All Time', start: null, end: null),
      DateRange(label: 'Custom date range', shortLabel: 'Custom', start: _selected.start, end: _selected.end),
    ];
  }

  String _formatRangeLabel(DateRange range) {
    if (range.start == null || range.end == null) return 'All dates';
    final df = DateFormat('dd MMM yyyy');
    final start = DateTime(range.start!.year, range.start!.month, range.start!.day);
    final end = DateTime(range.end!.year, range.end!.month, range.end!.day);
    if (start == end) return df.format(start);
    return '${df.format(start)} - ${df.format(end)}';
  }

  Future<DateTimeRange?> _showCustomRangePicker() async {
    final now = DateTime.now();
    final initialStart = _selected.start ?? DateTime(now.year, now.month, 1);
    final initialEnd = _selected.end ?? DateTime(now.year, now.month + 1, 0);
    final safeStart = DateTime(initialStart.year, initialStart.month, initialStart.day);
    final safeEnd = DateTime(initialEnd.year, initialEnd.month, initialEnd.day);

    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: DateTimeRange(start: safeStart, end: safeEnd),
      helpText: 'Select date range',
      confirmText: 'Apply',
      cancelText: 'Cancel',
      saveText: 'Apply',
      fieldStartHintText: 'Start date',
      fieldEndHintText: 'End date',
      currentDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      switchToInputEntryModeIcon: const Icon(Icons.edit_calendar_rounded),
      switchToCalendarEntryModeIcon: const Icon(Icons.calendar_month_rounded),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: _accent,
              onPrimary: Colors.white,
              secondary: _accent,
              onSecondary: Colors.white,
              surface: Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: const Color(0xFFF9FAFB),
              headerForegroundColor: const Color(0xFF374151),
              rangeSelectionBackgroundColor: _accent.withAlpha(45),
              rangeSelectionOverlayColor: WidgetStateProperty.all(_accent.withAlpha(24)),
              todayBorder: const BorderSide(color: _accent),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return const Color(0xFF374151);
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return _accent;
                return null;
              }),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _accent,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = _generateDateRanges();
    final isSmall = MediaQuery.of(context).size.width < 900;
    final chips = options.map((range) {
      final selected = _selected.shortLabel == range.shortLabel;
      final isCustom = range.shortLabel == 'Custom';
      return Tooltip(
        message: selected ? '${range.label}\n${_formatRangeLabel(_selected)}' : range.label,
        child: GestureDetector(
          onTap: () async {
            if (isCustom) {
              final picked = await _showCustomRangePicker();
              if (picked == null) return;
              final custom = DateRange(
                label:
                    'Custom (${DateFormat('dd MMM yyyy').format(picked.start)} – ${DateFormat('dd MMM yyyy').format(picked.end)})',
                shortLabel: 'Custom',
                start: picked.start,
                end: picked.end,
              );
              setState(() => _selected = custom);
              widget.onSelected(custom);
              return;
            }

            setState(() => _selected = range);
            widget.onSelected(range);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _accent : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? _accent : const Color(0xFFE5E7EB)),
              boxShadow: selected
                  ? [BoxShadow(color: _accent.withAlpha(42), blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                ] else if (isCustom) ...[
                  const Icon(Icons.tune_rounded, size: 13, color: Color(0xFF6B7280)),
                  const SizedBox(width: 5),
                ],
                Text(
                  range.shortLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return Align(
      alignment: Alignment.centerLeft,
      child: isSmall
          ? Wrap(spacing: 8, runSpacing: 8, children: chips)
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: chips
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(left: entry.key == 0 ? 0 : 8),
                        child: entry.value,
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}
