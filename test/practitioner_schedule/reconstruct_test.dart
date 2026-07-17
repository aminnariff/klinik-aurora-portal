import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_helper.dart';

void main() {
  group('reconstructSchedule', () {
    test('rebuilds a weekly range from consecutive slots (gap-aware)', () {
      // Monday 2026-08-03: 9:00, 9:45, 10:30 with a 45-min gap → range 9:00–11:15
      final iso = toUtcIsoList([
        DateTime(2026, 8, 3, 9, 0),
        DateTime(2026, 8, 3, 9, 45),
        DateTime(2026, 8, 3, 10, 30),
      ]);
      final schedule = reconstructSchedule(iso,
          from: DateTime(2026, 8, 1), until: DateTime(2026, 8, 31), gapMinutes: 45);
      final mon = schedule.pattern.dayRanges['Mon']!;
      expect(mon.single.start, const TimeOfDay(hour: 9, minute: 0));
      expect(mon.single.end, const TimeOfDay(hour: 11, minute: 15));
    });

    test('splits clusters separated by more than one gap into ranges (breaks)', () {
      // 9:00, 9:30 then 14:00, 14:30 with 30-min gap → 9:00–10:00 and 14:00–15:00
      final iso = toUtcIsoList([
        DateTime(2026, 8, 3, 9, 0),
        DateTime(2026, 8, 3, 9, 30),
        DateTime(2026, 8, 3, 14, 0),
        DateTime(2026, 8, 3, 14, 30),
      ]);
      final schedule = reconstructSchedule(iso,
          from: DateTime(2026, 8, 1), until: DateTime(2026, 8, 31), gapMinutes: 30);
      final mon = schedule.pattern.dayRanges['Mon']!;
      expect(mon, hasLength(2));
      expect(mon[0].end, const TimeOfDay(hour: 10, minute: 0));
      expect(mon[1].start, const TimeOfDay(hour: 14, minute: 0));
    });

    test('ignores slots outside the requested period', () {
      final iso = toUtcIsoList([DateTime(2026, 7, 6, 9, 0)]); // July Monday
      final schedule = reconstructSchedule(iso,
          from: DateTime(2026, 8, 1), until: DateTime(2026, 8, 31), gapMinutes: 30);
      expect(schedule.pattern.isEmpty, isTrue);
    });

    test('groups mixed weekdays into separate day keys', () {
      // Mon 2026-08-03 morning, Wed 2026-08-05 afternoon.
      final iso = toUtcIsoList([
        DateTime(2026, 8, 3, 9, 0),
        DateTime(2026, 8, 3, 9, 30),
        DateTime(2026, 8, 5, 14, 0),
      ]);
      final schedule = reconstructSchedule(iso,
          from: DateTime(2026, 8, 1), until: DateTime(2026, 8, 31), gapMinutes: 30);
      expect(schedule.pattern.dayRanges.keys.toSet(), {'Mon', 'Wed'});
      expect(schedule.pattern.dayRanges['Mon']!.single.start, const TimeOfDay(hour: 9, minute: 0));
      expect(schedule.pattern.dayRanges['Wed']!.single.start, const TimeOfDay(hour: 14, minute: 0));
    });

    test('unions different times of the same weekday across weeks', () {
      // Mon 2026-08-03 @ 9:00 and Mon 2026-08-10 @ 14:00 → two ranges on Mon.
      final iso = toUtcIsoList([
        DateTime(2026, 8, 3, 9, 0),
        DateTime(2026, 8, 10, 14, 0),
      ]);
      final schedule = reconstructSchedule(iso,
          from: DateTime(2026, 8, 1), until: DateTime(2026, 8, 31), gapMinutes: 30);
      final mon = schedule.pattern.dayRanges['Mon']!;
      expect(mon, hasLength(2));
      expect(mon[0].start, const TimeOfDay(hour: 9, minute: 0));
      expect(mon[1].start, const TimeOfDay(hour: 14, minute: 0));
    });

    test('caps inferred range end at 23:59', () {
      final iso = toUtcIsoList([DateTime(2026, 8, 3, 23, 30)]);
      final schedule = reconstructSchedule(iso,
          from: DateTime(2026, 8, 1), until: DateTime(2026, 8, 31), gapMinutes: 60);
      expect(schedule.pattern.dayRanges['Mon']!.single.end, const TimeOfDay(hour: 23, minute: 59));
    });
  });
}
