import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

/// When an announcement goes out.
///
/// A single nullable [value] carries both states — `null` means "send as soon
/// as the admin confirms", anything else is a queued send. Keeping it to one
/// field avoids the classic bug where a stale time lingers behind a
/// "send now" toggle and gets submitted by accident.
class NotificationDeliveryField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  /// Whether "Send now" is offered. False when editing an already-queued
  /// notification, where switching to immediate has no meaning — the caller
  /// wants a new time, not a send.
  final bool allowImmediate;

  const NotificationDeliveryField({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowImmediate = true,
  });

  /// Minutes offered in the picker, aligned to the cron's tick.
  ///
  /// Offering finer steps than the cron runs would let an admin pick 3:15 and
  /// then watch it arrive at 3:20 — the UI would be promising a precision the
  /// backend never had. Aligning them means the chosen time *is* the send time.
  static List<int> get _minuteSteps {
    final step = scheduledNotificationInterval.inMinutes.clamp(1, 60);
    return [for (var m = 0; m < 60; m += step) m];
  }

  bool get _isScheduled => value != null;

  /// Next available tick after a short buffer, so switching to "schedule" lands
  /// on a slot the cron will actually reach rather than one already past.
  static DateTime _defaultSchedule() {
    final step = scheduledNotificationInterval.inMinutes.clamp(1, 60);
    final base = DateTime.now().add(scheduledNotificationInterval);
    // Round up to the next aligned slot. DateTime normalises any hour or day
    // overflow that rounding up produces.
    final rounded = ((base.minute / step).ceil()) * step;
    return DateTime(base.year, base.month, base.day, base.hour, rounded);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3)),
        const SizedBox(height: 8),
        if (allowImmediate) ...[
          _ModeToggle(
            isScheduled: _isScheduled,
            onSendNow: () => onChanged(null),
            onSchedule: () => onChanged(_defaultSchedule()),
          ),
          const SizedBox(height: 12),
        ],
        if (_isScheduled) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 420;
              final date = _DateField(value: value!, onChanged: onChanged);
              final time = _TimeFields(value: value!, minuteSteps: _minuteSteps, onChanged: onChanged);

              return stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [date, const SizedBox(height: 12), time],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: date),
                        const SizedBox(width: 16),
                        Expanded(flex: 6, child: time),
                      ],
                    );
            },
          ),
          const SizedBox(height: 10),
        ],
        _Summary(value: value),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isScheduled;
  final VoidCallback onSendNow;
  final VoidCallback onSchedule;

  const _ModeToggle({required this.isScheduled, required this.onSendNow, required this.onSchedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(label: 'Send now', icon: Icons.send_rounded, isSelected: !isScheduled, onTap: onSendNow),
          const SizedBox(width: 4),
          _ToggleOption(
            label: 'Schedule for later',
            icon: Icons.schedule_rounded,
            isSelected: isScheduled,
            onTap: onSchedule,
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4)] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: isSelected ? secondaryColor : const Color(0xFF637381)),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.bodyMedium(context).apply(
                  color: isSelected ? textPrimaryColor : const Color(0xFF637381),
                  fontWeightDelta: isSelected ? 3 : 0,
                  fontSizeDelta: -1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({required this.value, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      barrierDismissible: true,
      dialogBackgroundColor: Colors.white,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        selectedDayHighlightColor: secondaryColor,
        weekdayLabelTextStyle: TextStyle(color: Colors.grey.shade600),
        controlsTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        selectedDayTextStyle: const TextStyle(color: Colors.white),
        dayTextStyle: const TextStyle(color: Colors.black87),
        openedFromDialog: true,
      ),
      value: [value],
      dialogSize: Size(screenWidthByBreakpoint(90, 70, 50), screenHeightByBreakpoint(90, 80, 50)),
      borderRadius: BorderRadius.circular(20),
    );

    final picked = results?.firstOrNull;
    if (picked == null) return;

    // Keep the time the admin already chose; only the calendar day moves.
    onChanged(DateTime(picked.year, picked.month, picked.day, value.hour, value.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF637381), fontSizeDelta: -2),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatDeliveryDate(value),
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                  ),
                ),
                const Icon(Icons.calendar_month_rounded, color: primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeFields extends StatelessWidget {
  final DateTime value;
  final List<int> minuteSteps;
  final ValueChanged<DateTime?> onChanged;

  const _TimeFields({required this.value, required this.minuteSteps, required this.onChanged});

  int get _hour12 => value.hour % 12 == 0 ? 12 : value.hour % 12;
  bool get _isPm => value.hour >= 12;

  void _apply({int? hour12, int? minute, bool? isPm}) {
    final h12 = hour12 ?? _hour12;
    final pm = isPm ?? _isPm;
    final hour24 = (h12 % 12) + (pm ? 12 : 0);
    onChanged(DateTime(value.year, value.month, value.day, hour24, minute ?? value.minute));
  }

  @override
  Widget build(BuildContext context) {
    // A minute value typed in elsewhere may not sit on a step; surface it as an
    // extra option rather than silently snapping it to something else.
    final minutes = minuteSteps.contains(value.minute)
        ? minuteSteps
        : (<int>[...minuteSteps, value.minute]..sort());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time',
          style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF637381), fontSizeDelta: -2),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _Select<int>(
                value: _hour12,
                items: [for (var h = 1; h <= 12; h++) h],
                labelBuilder: (h) => h.toString().padLeft(2, '0'),
                onChanged: (h) => _apply(hour12: h),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(':', style: AppTypography.bodyLarge(context)),
            ),
            Expanded(
              child: _Select<int>(
                value: value.minute,
                items: minutes,
                labelBuilder: (m) => m.toString().padLeft(2, '0'),
                onChanged: (m) => _apply(minute: m),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Select<bool>(
                value: _isPm,
                items: const [false, true],
                labelBuilder: (pm) => pm ? 'PM' : 'AM',
                onChanged: (pm) => _apply(isPm: pm),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Select<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  const _Select({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(8),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: AppTypography.bodyMedium(context).apply(color: textPrimaryColor, fontWeightDelta: 1),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(value: item, child: Text(labelBuilder(item))),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final DateTime? value;

  const _Summary({required this.value});

  @override
  Widget build(BuildContext context) {
    final scheduled = value;

    if (scheduled == null) {
      return Text(
        'Goes out as soon as you confirm on the next step.',
        style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF637381), fontSizeDelta: -2),
      );
    }

    final isPast = !scheduled.isAfter(DateTime.now());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isPast ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
          size: 16,
          color: isPast ? const Color(0xFFB45309) : const Color(0xFF16A34A),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isPast
                ? 'That time has already passed — pick a time in the future.'
                : 'Goes out on ${formatDeliveryDate(scheduled)} at ${formatDeliveryTime(scheduled)}.',
            style: AppTypography.bodyMedium(context).apply(
              color: isPast ? const Color(0xFF92400E) : const Color(0xFF637381),
              fontSizeDelta: -2,
            ),
          ),
        ),
      ],
    );
  }
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Today", "Tomorrow", or "Sat, 15 Aug 2026".
String formatDeliveryDate(DateTime value) {
  final now = DateTime.now();
  final day = DateTime(value.year, value.month, value.day);
  final today = DateTime(now.year, now.month, now.day);
  final difference = day.difference(today).inDays;

  if (difference == 0) return 'Today';
  if (difference == 1) return 'Tomorrow';
  return '${_weekdays[value.weekday - 1]}, ${value.day} ${_months[value.month - 1]} ${value.year}';
}

/// "9:30 AM".
String formatDeliveryTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '$hour:${value.minute.toString().padLeft(2, '0')} ${value.hour >= 12 ? 'PM' : 'AM'}';
}
