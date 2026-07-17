import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_helper.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';

/// Month-grid preview of the schedule period. Tapping a date lets staff
/// exclude it (holiday/leave), set custom hours for just that date, or
/// reset it back to the weekly pattern. Mutates [dateOverrides] in place
/// and calls [onChanged].
class DateOverrideCalendar extends StatefulWidget {
  final DateTime from;
  final DateTime until;
  final WeeklyPattern Function() pattern;
  final Map<String, List<TimeRange>?> dateOverrides;
  final VoidCallback onChanged;

  const DateOverrideCalendar({
    super.key,
    required this.from,
    required this.until,
    required this.pattern,
    required this.dateOverrides,
    required this.onChanged,
  });

  @override
  State<DateOverrideCalendar> createState() => _DateOverrideCalendarState();
}

class _DateOverrideCalendarState extends State<DateOverrideCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.from.year, widget.from.month);
  }

  @override
  void didUpdateWidget(covariant DateOverrideCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-clamp the visible month when the period changes, so we never keep
    // showing a month that fell outside the new [from, until] range.
    final first = DateTime(widget.from.year, widget.from.month);
    final last = DateTime(widget.until.year, widget.until.month);
    if (_month.isBefore(first)) _month = first;
    if (_month.isAfter(last)) _month = last;
  }

  bool get _canPrev => _month.isAfter(DateTime(widget.from.year, widget.from.month));
  bool get _canNext => _month.isBefore(DateTime(widget.until.year, widget.until.month));

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday; // 1 = Mon
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(DateFormat('MMMM yyyy').format(_month),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              onPressed: _canPrev ? () => setState(() => _month = DateTime(_month.year, _month.month - 1)) : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              onPressed: _canNext ? () => setState(() => _month = DateTime(_month.year, _month.month + 1)) : null,
            ),
          ],
        ),
        Row(
          children: [
            for (final d in weekDayKeys)
              Expanded(
                child: Center(
                  child: Text(d,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var week = 0; week * 7 < firstWeekday - 1 + daysInMonth; week++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(child: _cell(week * 7 + col - (firstWeekday - 1) + 1, daysInMonth)),
            ],
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            _legend(const Color(0xFFDCFCE7), 'Has slots'),
            _legend(const Color(0xFFFFE4E6), 'Excluded'),
            _legend(const Color(0xFFFEF3C7), 'Custom hours'),
            _legend(const Color(0xFFF3F4F6), 'No slots'),
          ],
        ),
      ],
    );
  }

  Widget _cell(int dayNumber, int daysInMonth) {
    if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox(height: 34);
    final date = DateTime(_month.year, _month.month, dayNumber);
    final inPeriod = !date.isBefore(DateTime(widget.from.year, widget.from.month, widget.from.day)) &&
        !date.isAfter(DateTime(widget.until.year, widget.until.month, widget.until.day));
    final key = dateKey(date);
    final overridden = widget.dateOverrides.containsKey(key);
    final excluded = overridden && widget.dateOverrides[key] == null;
    final hasPattern = widget.pattern().rangesForWeekday(date.weekday).isNotEmpty;

    Color background;
    if (!inPeriod) {
      background = Colors.transparent;
    } else if (excluded) {
      background = const Color(0xFFFFE4E6);
    } else if (overridden) {
      background = const Color(0xFFFEF3C7);
    } else if (hasPattern) {
      background = const Color(0xFFDCFCE7);
    } else {
      background = const Color(0xFFF3F4F6);
    }

    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: InkWell(
        onTap: inPeriod ? () => _editDate(date) : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 31,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
          child: Text(
            '$dayNumber',
            style: TextStyle(
              fontSize: 11,
              color: inPeriod ? const Color(0xFF111827) : Colors.grey[300],
              decoration: excluded ? TextDecoration.lineThrough : null,
              fontWeight: overridden ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  /// The ranges currently in effect for [date]: its override when one
  /// exists (null = excluded), otherwise the weekly pattern.
  List<TimeRange>? _effectiveRanges(String key, DateTime date) =>
      widget.dateOverrides.containsKey(key)
          ? widget.dateOverrides[key]
          : widget.pattern().rangesForWeekday(date.weekday);

  Future<void> _editDate(DateTime date) async {
    final key = dateKey(date);
    final overridden = widget.dateOverrides.containsKey(key);
    final excluded = overridden && widget.dateOverrides[key] == null;
    final effective = _effectiveRanges(key, date);

    final String statusLabel;
    final Color statusColor;
    if (excluded) {
      statusLabel = 'No slots (excluded)';
      statusColor = const Color(0xFFDC2626);
    } else if (overridden) {
      statusLabel = 'Custom hours';
      statusColor = const Color(0xFFB45309);
    } else if (effective != null && effective.isNotEmpty) {
      statusLabel = 'Weekly pattern';
      statusColor = const Color(0xFF16A34A);
    } else {
      statusLabel = 'No working hours set';
      statusColor = const Color(0xFF6B7280);
    }

    final hoursLabel = (effective == null || effective.isEmpty)
        ? null
        : effective
            .map((r) => '${_formatTime(context, r.start)} – ${_formatTime(context, r.end)}')
            .join(', ');

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMM yyyy').format(date),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                  if (hoursLabel != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hoursLabel,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              if (!excluded)
                _dateActionTile(
                  ctx,
                  icon: Icons.event_busy_rounded,
                  color: const Color(0xFFDC2626),
                  title: 'No slots this day',
                  subtitle: 'Public holiday, leave, or day off — no appointments can be booked.',
                  result: 'exclude',
                ),
              _dateActionTile(
                ctx,
                icon: Icons.edit_calendar_rounded,
                color: const Color(0xFFB45309),
                title: excluded ? 'Set hours for this day' : 'Custom hours for this day only',
                subtitle: 'Different working hours just for this date — other days are unaffected.',
                result: 'custom',
              ),
              if (overridden)
                _dateActionTile(
                  ctx,
                  icon: Icons.restart_alt_rounded,
                  color: const Color(0xFF16A34A),
                  title: 'Reset to weekly pattern',
                  subtitle: 'Remove this day\'s exception and follow the normal weekly hours.',
                  result: 'reset',
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null) return;
    if (action == 'exclude') {
      widget.dateOverrides[key] = null;
    } else if (action == 'reset') {
      widget.dateOverrides.remove(key);
    } else if (action == 'custom') {
      final initial = widget.dateOverrides[key] ??
          widget.pattern().rangesForWeekday(date.weekday).map((r) => TimeRange(start: r.start, end: r.end)).toList();
      final edited = await _editRanges(date, initial);
      if (edited == null) return;
      // Saving no ranges means "no slots this day" — record it as an exclusion
      // so the calendar shows it red, not amber.
      widget.dateOverrides[key] = edited.isEmpty ? null : edited;
    }
    setState(() {});
    widget.onChanged();
  }

  Future<List<TimeRange>?> _editRanges(DateTime date, List<TimeRange> initial) {
    final working = initial.map((r) => TimeRange(start: r.start, end: r.end)).toList();
    return showDialog<List<TimeRange>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Hours for ${DateFormat('d MMM').format(date)}', style: const TextStyle(fontSize: 15)),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < working.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _timeChip(ctx, working[i].start, (t) => setDialogState(() => working[i].start = t)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded, size: 14),
                        ),
                        _timeChip(ctx, working[i].end, (t) => setDialogState(() => working[i].end = t)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 18, color: Colors.redAccent),
                          onPressed: () => setDialogState(() => working.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => setDialogState(() => working.add(
                        TimeRange(
                          start: const TimeOfDay(hour: 9, minute: 0),
                          end: const TimeOfDay(hour: 17, minute: 0),
                        ),
                      )),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add range', style: TextStyle(fontSize: 12)),
                ),
                if (working.any((r) => !_isRangeValid(r)))
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text('Start must be before End.', style: TextStyle(fontSize: 11, color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: Colors.white),
              onPressed: working.any((r) => !_isRangeValid(r)) ? null : () => Navigator.pop(ctx, working),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isRangeValid(TimeRange r) =>
      r.start.hour * 60 + r.start.minute < r.end.hour * 60 + r.end.minute;

  String _formatTime(BuildContext ctx, TimeOfDay t) => t.format(ctx);

  Widget _dateActionTile(
    BuildContext ctx, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String result,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.pop(ctx, result),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.3),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeChip(BuildContext ctx, TimeOfDay time, ValueChanged<TimeOfDay> onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: ctx, initialTime: time);
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
        child: Text(time.format(ctx), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
