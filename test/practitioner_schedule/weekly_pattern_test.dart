import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';

void main() {
  group('TimeRange', () {
    test('serializes and deserializes', () {
      final range = TimeRange(
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 17, minute: 30),
      );
      final json = range.toJson();
      expect(json, {'start': '09:00', 'end': '17:30'});
      final restored = TimeRange.fromJson(json);
      expect(restored.start, const TimeOfDay(hour: 9, minute: 0));
      expect(restored.end, const TimeOfDay(hour: 17, minute: 30));
    });

    test('detects overlap', () {
      final a = TimeRange(start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 12, minute: 0));
      final b = TimeRange(start: const TimeOfDay(hour: 11, minute: 0), end: const TimeOfDay(hour: 13, minute: 0));
      final c = TimeRange(start: const TimeOfDay(hour: 12, minute: 0), end: const TimeOfDay(hour: 13, minute: 0));
      expect(a.overlapsWith(b), isTrue);
      expect(a.overlapsWith(c), isFalse); // touching is not overlapping
    });
  });

  group('WeeklyPattern', () {
    test('round-trips through JSON and drops empty days', () {
      final pattern = WeeklyPattern(dayRanges: {
        'Mon': [TimeRange(start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 13, minute: 0))],
        'Tue': [],
      });
      final json = pattern.toJson();
      expect(json.containsKey('Tue'), isFalse);
      final restored = WeeklyPattern.fromJson(json);
      expect(restored.dayRanges['Mon']!.single.end, const TimeOfDay(hour: 13, minute: 0));
    });

    test('rangesForWeekday maps DateTime.weekday to day keys', () {
      final pattern = WeeklyPattern(dayRanges: {
        'Sun': [TimeRange(start: const TimeOfDay(hour: 10, minute: 0), end: const TimeOfDay(hour: 12, minute: 0))],
      });
      expect(pattern.rangesForWeekday(DateTime.sunday), hasLength(1));
      expect(pattern.rangesForWeekday(DateTime.monday), isEmpty);
    });
  });

  group('AvailabilitySchedule', () {
    test('round-trips through JSON including null (excluded) overrides', () {
      final schedule = AvailabilitySchedule(
        pattern: WeeklyPattern(dayRanges: {
          'Mon': [TimeRange(start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 17, minute: 0))],
        }),
        availableFrom: DateTime(2026, 8, 1),
        availableUntil: DateTime(2026, 9, 30),
        dateOverrides: {
          '2026-08-31': null, // public holiday: excluded
          '2026-08-05': [TimeRange(start: const TimeOfDay(hour: 14, minute: 0), end: const TimeOfDay(hour: 17, minute: 0))],
        },
      );
      final restored = AvailabilitySchedule.fromJson(schedule.toJson());
      expect(restored.availableFrom, DateTime(2026, 8, 1));
      expect(restored.availableUntil, DateTime(2026, 9, 30));
      expect(restored.dateOverrides['2026-08-31'], isNull);
      expect(restored.dateOverrides.containsKey('2026-08-31'), isTrue);
      expect(restored.dateOverrides['2026-08-05']!.single.start, const TimeOfDay(hour: 14, minute: 0));
    });
  });
}
