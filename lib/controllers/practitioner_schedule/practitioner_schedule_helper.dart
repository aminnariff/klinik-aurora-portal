import 'package:flutter/material.dart';
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
  // Overlapping ranges on the same day can emit the same slot twice — dedupe.
  final deduped = result.toSet().toList()..sort();
  return deduped;
}

/// Server storage format, matching MultiTimeCalendarPage._getAllDateTimeValues.
List<String> toUtcIsoList(List<DateTime> localSlots) =>
    localSlots.map((d) => d.toUtc().toIso8601String()).toList();

/// The "replace within period, keep the rest" rule: existing UTC ISO slots
/// whose LOCAL date falls inside [from, until] (inclusive, whole days) are
/// dropped; everything else is kept and merged with [replacement].
///
/// Precondition: entries must be canonical UTC 'Z' ISO-8601 strings as
/// produced by [toUtcIsoList] — offset or naive strings are not supported
/// (dedupe is by string identity and the final sort is lexical).
/// Unparseable existing entries are silently dropped.
List<String> mergeReplacePeriod({
  required List<String> existing,
  required List<String> replacement,
  required DateTime from,
  required DateTime until,
}) {
  final fromDay = DateTime(from.year, from.month, from.day);
  final untilExclusive = DateTime(until.year, until.month, until.day + 1);
  final kept = existing.where((iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return false;
    return dt.isBefore(fromDay) || !dt.isBefore(untilExclusive);
  });
  // All entries are UTC 'Z' strings, so lexical sort == chronological sort.
  return {...kept, ...replacement}.toList()..sort();
}

/// Best-effort inverse of expandSchedule, for "Load from existing service"
/// when the saved pattern isn't on this device. Groups a service's stored
/// slots by weekday, then folds slot times spaced <= gapMinutes apart into
/// ranges (range end = last slot + gap, capped at 23:59). Result is marked
/// for editing, not assumed exact: when the same weekday has different
/// times across weeks, their union is applied to every occurrence of that
/// weekday, and a range's tail may overstate the true window by up to one
/// gap.
AvailabilitySchedule reconstructSchedule(
  List<String> utcIso, {
  required DateTime from,
  required DateTime until,
  required int gapMinutes,
}) {
  final fromDay = DateTime(from.year, from.month, from.day);
  final untilDay = DateTime(until.year, until.month, until.day);
  final byWeekday = <int, Set<int>>{};
  for (final iso in utcIso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) continue;
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day.isBefore(fromDay) || day.isAfter(untilDay)) continue;
    byWeekday.putIfAbsent(dt.weekday, () => <int>{}).add(dt.hour * 60 + dt.minute);
  }

  TimeOfDay fromMinutes(int m) {
    final capped = m > 23 * 60 + 59 ? 23 * 60 + 59 : m;
    return TimeOfDay(hour: capped ~/ 60, minute: capped % 60);
  }

  final dayRanges = <String, List<TimeRange>>{};
  byWeekday.forEach((weekday, minuteSet) {
    final sorted = minuteSet.toList()..sort();
    final ranges = <TimeRange>[];
    int? rangeStart;
    int? prev;
    for (final m in sorted) {
      if (rangeStart == null) {
        rangeStart = m;
      } else if (m - prev! > gapMinutes) {
        ranges.add(TimeRange(start: fromMinutes(rangeStart), end: fromMinutes(prev + gapMinutes)));
        rangeStart = m;
      }
      prev = m;
    }
    if (rangeStart != null) {
      ranges.add(TimeRange(start: fromMinutes(rangeStart), end: fromMinutes(prev! + gapMinutes)));
    }
    dayRanges[weekDayKeys[weekday - 1]] = ranges;
  });

  return AvailabilitySchedule(
    pattern: WeeklyPattern(dayRanges: dayRanges),
    availableFrom: from,
    availableUntil: until,
  );
}
