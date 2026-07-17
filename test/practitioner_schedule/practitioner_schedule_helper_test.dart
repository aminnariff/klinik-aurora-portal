import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_helper.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';

TimeRange range(int sh, int sm, int eh, int em) =>
    TimeRange(start: TimeOfDay(hour: sh, minute: sm), end: TimeOfDay(hour: eh, minute: em));

void main() {
  // 2026-08-03 is a Monday.
  final mondayOnly = WeeklyPattern(dayRanges: {'Mon': [range(9, 0, 10, 30)]});
  final past = DateTime(2026, 1, 1); // "now" far before the period → no past filtering

  group('parseServiceTimeToMinutes', () {
    test('parses minutes and hours', () {
      expect(parseServiceTimeToMinutes('45 minutes'), 45);
      expect(parseServiceTimeToMinutes('1 hour'), 60);
      expect(parseServiceTimeToMinutes('2 hours'), 120);
    });
    test('falls back to 30 on garbage or null', () {
      expect(parseServiceTimeToMinutes('soon'), 30);
      expect(parseServiceTimeToMinutes(null), 30);
    });
  });

  group('expandSchedule', () {
    test('45-min gap in a 9:00–10:30 window yields 9:00 and 9:45', () {
      final schedule = AvailabilitySchedule(
        pattern: mondayOnly,
        availableFrom: DateTime(2026, 8, 3),
        availableUntil: DateTime(2026, 8, 3),
      );
      final slots = expandSchedule(schedule, 45, now: past);
      expect(slots, [DateTime(2026, 8, 3, 9, 0), DateTime(2026, 8, 3, 9, 45)]);
    });

    test('different gaps produce different times from the same window', () {
      final schedule = AvailabilitySchedule(
        pattern: mondayOnly,
        availableFrom: DateTime(2026, 8, 3),
        availableUntil: DateTime(2026, 8, 3),
      );
      expect(expandSchedule(schedule, 30, now: past), hasLength(3)); // 9:00 9:30 10:00
      expect(expandSchedule(schedule, 45, now: past), hasLength(2)); // 9:00 9:45
    });

    test('multiple ranges model breaks: 9–11 and 14–16 with 60-min gap', () {
      final schedule = AvailabilitySchedule(
        pattern: WeeklyPattern(dayRanges: {'Mon': [range(9, 0, 11, 0), range(14, 0, 16, 0)]}),
        availableFrom: DateTime(2026, 8, 3),
        availableUntil: DateTime(2026, 8, 3),
      );
      final slots = expandSchedule(schedule, 60, now: past);
      expect(slots.map((d) => d.hour).toList(), [9, 10, 14, 15]); // 11–14 break has no slots
    });

    test('honors period bounds inclusively across weeks', () {
      final schedule = AvailabilitySchedule(
        pattern: mondayOnly,
        availableFrom: DateTime(2026, 8, 4), // Tue, after first Monday
        availableUntil: DateTime(2026, 8, 17), // a Monday, inclusive
      );
      final slots = expandSchedule(schedule, 45, now: past);
      final days = slots.map((d) => d.day).toSet();
      expect(days, {10, 17}); // Mondays 10th and 17th only
    });

    test('excluded date override yields no slots that day', () {
      final schedule = AvailabilitySchedule(
        pattern: mondayOnly,
        availableFrom: DateTime(2026, 8, 3),
        availableUntil: DateTime(2026, 8, 10),
        dateOverrides: {'2026-08-10': null},
      );
      final slots = expandSchedule(schedule, 45, now: past);
      expect(slots.map((d) => d.day).toSet(), {3});
    });

    test('per-date override replaces the weekly pattern for that date only', () {
      final schedule = AvailabilitySchedule(
        pattern: mondayOnly,
        availableFrom: DateTime(2026, 8, 3),
        availableUntil: DateTime(2026, 8, 10),
        dateOverrides: {'2026-08-10': [range(15, 0, 16, 0)]},
      );
      final slots = expandSchedule(schedule, 30, now: past);
      final aug10 = slots.where((d) => d.day == 10).toList();
      expect(aug10, [DateTime(2026, 8, 10, 15, 0), DateTime(2026, 8, 10, 15, 30)]);
    });

    test('filters slots before today, keeps today itself', () {
      final schedule = AvailabilitySchedule(
        pattern: WeeklyPattern(dayRanges: {
          for (final d in weekDayKeys) d: [range(9, 0, 10, 0)],
        }),
        availableFrom: DateTime(2026, 8, 1),
        availableUntil: DateTime(2026, 8, 31),
      );
      final slots = expandSchedule(schedule, 60, now: DateTime(2026, 8, 10, 23, 0));
      expect(slots.first, DateTime(2026, 8, 10, 9, 0)); // today kept even though 9:00 < 23:00
      expect(slots.any((d) => d.day < 10), isFalse);
    });

    test('zero or negative gap returns empty rather than looping forever', () {
      final schedule = AvailabilitySchedule(
        pattern: mondayOnly,
        availableFrom: DateTime(2026, 8, 3),
        availableUntil: DateTime(2026, 8, 3),
      );
      expect(expandSchedule(schedule, 0, now: past), isEmpty);
      expect(expandSchedule(schedule, -15, now: past), isEmpty);
    });
  });
}
