import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';

/// Canonical 'yyyy-MM-dd' key used by dateOverrides and the override calendar.
String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Parses serviceTime strings like '45 minutes' / '1 hour'.
/// Same rule as MultiTimeCalendarPage.convertToMinutes.
int parseServiceTimeToMinutes(String? input, {int fallback = 30}) {
  if (input == null) return fallback;
  try {
    final match = RegExp(r'^(\d+)\s*(minute|minutes|hour|hours)$').firstMatch(input.toLowerCase().trim());
    if (match != null) {
      final val = int.parse(match.group(1)!);
      return match.group(2)!.startsWith('hour') ? val * 60 : val;
    }
  } catch (_) {}
  return fallback;
}

/// Expands a schedule into concrete local DateTimes for one service:
/// every [gapMinutes] step whose start is strictly before the range end
/// (same rule as the existing WeeklySlotGenerator), bounded to the
/// schedule period (inclusive), honoring dateOverrides, dropping dates
/// before today ([now] overridable for tests).
List<DateTime> expandSchedule(AvailabilitySchedule schedule, int gapMinutes, {DateTime? now}) {
  if (gapMinutes <= 0) return [];
  final result = <DateTime>[];
  final nowLocal = now ?? DateTime.now();
  final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  var day = DateTime(schedule.availableFrom.year, schedule.availableFrom.month, schedule.availableFrom.day);
  final last = DateTime(schedule.availableUntil.year, schedule.availableUntil.month, schedule.availableUntil.day);
  while (!day.isAfter(last)) {
    if (!day.isBefore(today)) {
      final key = dateKey(day);
      final List<TimeRange>? ranges = schedule.dateOverrides.containsKey(key)
          ? schedule.dateOverrides[key]
          : schedule.pattern.rangesForWeekday(day.weekday);
      if (ranges != null) {
        for (final range in ranges) {
          var minutes = range.start.hour * 60 + range.start.minute;
          final endMinutes = range.end.hour * 60 + range.end.minute;
          while (minutes < endMinutes) {
            result.add(DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60));
            minutes += gapMinutes;
          }
        }
      }
    }
    day = DateTime(day.year, day.month, day.day + 1); // calendar-day step, DST-safe
  }
  result.sort();
  return result;
}
