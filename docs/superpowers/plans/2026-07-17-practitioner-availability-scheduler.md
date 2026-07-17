# Practitioner Availability Scheduler Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A wizard where staff pick a practitioner type (Doctor/Sonographer/Therapist/Spa Therapist/Dietitian), set an availability window for a date range, and apply generated slots to every active service of that type at the branch — each service keeping its own editable gap (interval).

**Architecture:** A pure-logic layer (`WeeklyPattern`/`AvailabilitySchedule` models + expansion/merge helpers, fully unit-tested) feeds a 3-step wizard dialog. The weekly pattern editor is extracted out of the existing `WeeklySlotGenerator` into a shared widget. Saving goes through `PractitionerScheduleSaver`, which calls a new `bulk-upsert` endpoint when enabled, or falls back to the existing per-service create/update loop. No data-model changes: slots are still stored per `serviceBranchId` in `service-available-datetime`, so the patient app and all admin reads are untouched.

**Tech Stack:** Flutter (Provider, Dio via existing `ApiController`), `flutter_test` for unit tests, `SharedPreferences` (existing `prefs` global from `lib/config/storage.dart`).

**Spec:** `docs/superpowers/specs/2026-07-17-practitioner-availability-scheduler-design.md`

**Conventions used throughout:**
- Run all commands from repo root `/Users/aminariff/Documents/Github/klinik-aurora-portal`.
- `responseCode(...)` from `lib/controllers/api_response_controller.dart` is the success check for API calls.
- `prefs` is a global `SharedPreferences` instance from `lib/config/storage.dart`.
- Datetimes are stored on the server as UTC ISO-8601 strings (`DateTime.toUtc().toIso8601String()`).
- After each task: `flutter analyze` must report no NEW issues (run it before Task 1 once and note the baseline count).

---

### Task 1: Pattern & schedule models

**Files:**
- Create: `lib/models/practitioner_schedule/weekly_pattern.dart`
- Modify: `lib/views/service/slot_generator.dart` (remove local `TimeRange`, re-export)
- Test: `test/practitioner_schedule/weekly_pattern_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/practitioner_schedule/weekly_pattern_test.dart`:

```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/practitioner_schedule/weekly_pattern_test.dart`
Expected: FAIL — `Target of URI doesn't exist ... weekly_pattern.dart`

- [ ] **Step 3: Create the models file**

Create `lib/models/practitioner_schedule/weekly_pattern.dart`:

```dart
import 'package:flutter/material.dart';

/// Day keys used across the pattern UI and persistence, Mon-first.
/// Index i corresponds to DateTime.weekday == i + 1.
const List<String> weekDayKeys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// A start–end range within a single day. Mutable because the pattern
/// editor updates start/end in place (matches the previous behavior in
/// slot_generator.dart, where this class originally lived).
class TimeRange {
  TimeOfDay start;
  TimeOfDay end;
  TimeRange({required this.start, required this.end});

  bool overlapsWith(TimeRange other) {
    final s1 = start.hour * 60 + start.minute;
    final e1 = end.hour * 60 + end.minute;
    final s2 = other.start.hour * 60 + other.start.minute;
    final e2 = other.end.hour * 60 + other.end.minute;
    return s1 < e2 && s2 < e1;
  }

  Map<String, dynamic> toJson() => {'start': formatTimeOfDay(start), 'end': formatTimeOfDay(end)};

  static TimeRange fromJson(Map<String, dynamic> json) =>
      TimeRange(start: parseTimeOfDay(json['start']), end: parseTimeOfDay(json['end']));
}

String formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay parseTimeOfDay(String s) {
  final parts = s.split(':').map(int.parse).toList();
  return TimeOfDay(hour: parts[0], minute: parts[1]);
}

/// The practitioner's recurring weekly availability window.
/// A day with no entry (or an empty list) means "not available".
class WeeklyPattern {
  final Map<String, List<TimeRange>> dayRanges;
  WeeklyPattern({Map<String, List<TimeRange>>? dayRanges}) : dayRanges = dayRanges ?? {};

  bool get isEmpty => dayRanges.values.every((ranges) => ranges.isEmpty);

  /// [weekday] is DateTime.weekday (1 = Monday … 7 = Sunday).
  List<TimeRange> rangesForWeekday(int weekday) => dayRanges[weekDayKeys[weekday - 1]] ?? [];

  Map<String, dynamic> toJson() => {
        for (final entry in dayRanges.entries)
          if (entry.value.isNotEmpty) entry.key: entry.value.map((r) => r.toJson()).toList(),
      };

  static WeeklyPattern fromJson(Map<String, dynamic> json) => WeeklyPattern(
        dayRanges: {
          for (final entry in json.entries)
            entry.key: (entry.value as List)
                .map((r) => TimeRange.fromJson(Map<String, dynamic>.from(r)))
                .toList(),
        },
      );
}

/// A weekly pattern bounded to a date range, with per-date manual overrides.
/// Override value semantics: key absent = follow the weekly pattern;
/// value null = excluded date (no slots); value non-null = replacement ranges.
class AvailabilitySchedule {
  WeeklyPattern pattern;
  DateTime availableFrom;
  DateTime availableUntil; // inclusive
  final Map<String, List<TimeRange>?> dateOverrides;

  AvailabilitySchedule({
    required this.pattern,
    required this.availableFrom,
    required this.availableUntil,
    Map<String, List<TimeRange>?>? dateOverrides,
  }) : dateOverrides = dateOverrides ?? {};

  Map<String, dynamic> toJson() => {
        'pattern': pattern.toJson(),
        'availableFrom': _formatDate(availableFrom),
        'availableUntil': _formatDate(availableUntil),
        'dateOverrides': {
          for (final entry in dateOverrides.entries)
            entry.key: entry.value?.map((r) => r.toJson()).toList(),
        },
      };

  static AvailabilitySchedule fromJson(Map<String, dynamic> json) => AvailabilitySchedule(
        pattern: WeeklyPattern.fromJson(Map<String, dynamic>.from(json['pattern'] ?? {})),
        availableFrom: DateTime.parse(json['availableFrom']),
        availableUntil: DateTime.parse(json['availableUntil']),
        dateOverrides: {
          for (final entry in Map<String, dynamic>.from(json['dateOverrides'] ?? {}).entries)
            entry.key: entry.value == null
                ? null
                : (entry.value as List)
                    .map((r) => TimeRange.fromJson(Map<String, dynamic>.from(r)))
                    .toList(),
        },
      );

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 4: Point `slot_generator.dart` at the moved TimeRange**

In `lib/views/service/slot_generator.dart`:

1. Delete the `class TimeRange { ... }` block at the bottom of the file (lines 1177–1189).
2. Add at the top, after the existing imports:

```dart
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';

// Kept so existing importers of slot_generator.dart still see TimeRange.
export 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart' show TimeRange;
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/practitioner_schedule/weekly_pattern_test.dart && flutter analyze lib/views/service/slot_generator.dart lib/models/practitioner_schedule/`
Expected: tests PASS, analyze clean.

- [ ] **Step 6: Commit**

```bash
git add lib/models/practitioner_schedule/weekly_pattern.dart lib/views/service/slot_generator.dart test/practitioner_schedule/weekly_pattern_test.dart
git commit -m "feat: add WeeklyPattern/AvailabilitySchedule models, relocate TimeRange"
```

---

### Task 2: Slot expansion helper

**Files:**
- Create: `lib/controllers/practitioner_schedule/practitioner_schedule_helper.dart`
- Test: `test/practitioner_schedule/practitioner_schedule_helper_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/practitioner_schedule/practitioner_schedule_helper_test.dart`:

```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/practitioner_schedule/practitioner_schedule_helper_test.dart`
Expected: FAIL — helper file doesn't exist.

- [ ] **Step 3: Create the helper**

Create `lib/controllers/practitioner_schedule/practitioner_schedule_helper.dart`:

```dart
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/practitioner_schedule/practitioner_schedule_helper_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/controllers/practitioner_schedule/practitioner_schedule_helper.dart test/practitioner_schedule/practitioner_schedule_helper_test.dart
git commit -m "feat: add schedule expansion helper with per-service gap support"
```

---

### Task 3: UTC conversion & replace-within-period merge

**Files:**
- Modify: `lib/controllers/practitioner_schedule/practitioner_schedule_helper.dart`
- Test: `test/practitioner_schedule/merge_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/practitioner_schedule/merge_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_helper.dart';

void main() {
  group('toUtcIsoList', () {
    test('converts local DateTimes to UTC ISO strings', () {
      final iso = toUtcIsoList([DateTime(2026, 8, 3, 9, 0)]);
      expect(iso, hasLength(1));
      expect(iso.single.endsWith('Z'), isTrue);
      expect(DateTime.parse(iso.single).toLocal(), DateTime(2026, 8, 3, 9, 0));
    });
  });

  group('mergeReplacePeriod', () {
    // Existing slots: one in July, one in August, one in October (all 09:00 local).
    final existing = toUtcIsoList([
      DateTime(2026, 7, 20, 9, 0),
      DateTime(2026, 8, 5, 9, 0),
      DateTime(2026, 10, 1, 9, 0),
    ]);
    final august = toUtcIsoList([DateTime(2026, 8, 10, 10, 0)]);

    test('keeps slots outside the period, replaces slots inside', () {
      final merged = mergeReplacePeriod(
        existing: existing,
        replacement: august,
        from: DateTime(2026, 8, 1),
        until: DateTime(2026, 9, 30),
      );
      final local = merged.map((s) => DateTime.parse(s).toLocal()).toList();
      expect(local, [
        DateTime(2026, 7, 20, 9, 0), // before period: kept
        DateTime(2026, 8, 10, 10, 0), // replacement
        DateTime(2026, 10, 1, 9, 0), // after period: kept
      ]);
    });

    test('period boundary days are replaced inclusively', () {
      final merged = mergeReplacePeriod(
        existing: toUtcIsoList([DateTime(2026, 8, 1, 8, 0), DateTime(2026, 9, 30, 23, 0)]),
        replacement: const [],
        from: DateTime(2026, 8, 1),
        until: DateTime(2026, 9, 30),
      );
      expect(merged, isEmpty);
    });

    test('deduplicates and sorts', () {
      final merged = mergeReplacePeriod(
        existing: august,
        replacement: august,
        from: DateTime(2026, 1, 1),
        until: DateTime(2026, 1, 2), // period does not cover august → existing kept
      );
      expect(merged, august);
    });

    test('drops unparseable existing entries instead of crashing', () {
      final merged = mergeReplacePeriod(
        existing: ['not-a-date'],
        replacement: august,
        from: DateTime(2026, 8, 1),
        until: DateTime(2026, 8, 31),
      );
      expect(merged, august);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/practitioner_schedule/merge_test.dart`
Expected: FAIL — `toUtcIsoList`/`mergeReplacePeriod` undefined.

- [ ] **Step 3: Append to the helper file**

Add to `lib/controllers/practitioner_schedule/practitioner_schedule_helper.dart`:

```dart
/// Server storage format, matching MultiTimeCalendarPage._getAllDateTimeValues.
List<String> toUtcIsoList(List<DateTime> localSlots) =>
    localSlots.map((d) => d.toUtc().toIso8601String()).toList();

/// The "replace within period, keep the rest" rule: existing UTC ISO slots
/// whose LOCAL date falls inside [from, until] (inclusive, whole days) are
/// dropped; everything else is kept and merged with [replacement].
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/practitioner_schedule/`
Expected: PASS (all files)

- [ ] **Step 5: Commit**

```bash
git add lib/controllers/practitioner_schedule/practitioner_schedule_helper.dart test/practitioner_schedule/merge_test.dart
git commit -m "feat: add UTC conversion and replace-within-period merge"
```

---

### Task 4: Schedule reconstruction ("Load from existing service")

**Files:**
- Modify: `lib/controllers/practitioner_schedule/practitioner_schedule_helper.dart`
- Test: `test/practitioner_schedule/reconstruct_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/practitioner_schedule/reconstruct_test.dart`:

```dart
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

    test('caps inferred range end at 23:59', () {
      final iso = toUtcIsoList([DateTime(2026, 8, 3, 23, 30)]);
      final schedule = reconstructSchedule(iso,
          from: DateTime(2026, 8, 1), until: DateTime(2026, 8, 31), gapMinutes: 60);
      expect(schedule.pattern.dayRanges['Mon']!.single.end, const TimeOfDay(hour: 23, minute: 59));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/practitioner_schedule/reconstruct_test.dart`
Expected: FAIL — `reconstructSchedule` undefined.

- [ ] **Step 3: Append to the helper file**

Add to `lib/controllers/practitioner_schedule/practitioner_schedule_helper.dart` (also add `import 'package:flutter/material.dart';` at the top of the file for `TimeOfDay`):

```dart
/// Best-effort inverse of expandSchedule, for "Load from existing service"
/// when the saved pattern isn't on this device. Groups a service's stored
/// slots by weekday, then folds slot times spaced <= gapMinutes apart into
/// ranges (range end = last slot + gap, capped at 23:59). Result is marked
/// for editing, not assumed exact.
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/practitioner_schedule/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/controllers/practitioner_schedule/practitioner_schedule_helper.dart test/practitioner_schedule/reconstruct_test.dart
git commit -m "feat: add schedule reconstruction from existing slots"
```

---

### Task 5: Bulk-upsert API models, controller method, and saver with fallback

**Files:**
- Create: `lib/models/practitioner_schedule/schedule_payload.dart`
- Create: `lib/models/practitioner_schedule/bulk_upsert_response.dart`
- Modify: `lib/controllers/service/service_branch_available_dt_controller.dart`
- Create: `lib/controllers/practitioner_schedule/practitioner_schedule_saver.dart`
- Test: `test/practitioner_schedule/bulk_upsert_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/practitioner_schedule/bulk_upsert_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/bulk_upsert_response.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/schedule_payload.dart';

void main() {
  test('SchedulePayload serializes to the bulk-upsert item shape', () {
    final payload = SchedulePayload(
      serviceBranchId: 'sb-1',
      serviceName: 'Consultation',
      existingRecordId: null,
      availableDatetimes: ['2026-08-03T01:00:00.000Z'],
    );
    expect(payload.toBulkItemJson(), {
      'serviceBranchId': 'sb-1',
      'availableDatetimes': ['2026-08-03T01:00:00.000Z'],
    });
  });

  test('BulkUpsertAvailableDtResponse parses per-item results', () {
    final response = BulkUpsertAvailableDtResponse.fromJson({
      'code': 200,
      'message': 'ok',
      'data': [
        {'serviceBranchId': 'sb-1', 'success': true},
        {'serviceBranchId': 'sb-2', 'success': false, 'message': 'not found'},
      ],
    });
    expect(response.data, hasLength(2));
    expect(response.data![1].success, isFalse);
    expect(response.data![1].message, 'not found');
  });

  test('BulkUpsertAvailableDtResponse tolerates missing data', () {
    final response = BulkUpsertAvailableDtResponse.fromJson({'code': 200});
    expect(response.data, isNull);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/practitioner_schedule/bulk_upsert_test.dart`
Expected: FAIL — model files don't exist.

- [ ] **Step 3: Create the models**

Create `lib/models/practitioner_schedule/schedule_payload.dart`:

```dart
/// One target service's fully-merged datetime list, ready to save.
class SchedulePayload {
  final String serviceBranchId;
  final String serviceName;

  /// Existing serviceBranchAvailableDatetimeId; null means no record yet
  /// (fallback path calls create instead of update).
  final String? existingRecordId;
  final List<String> availableDatetimes;

  SchedulePayload({
    required this.serviceBranchId,
    required this.serviceName,
    required this.existingRecordId,
    required this.availableDatetimes,
  });

  Map<String, dynamic> toBulkItemJson() => {
        'serviceBranchId': serviceBranchId,
        'availableDatetimes': availableDatetimes,
      };
}
```

Create `lib/models/practitioner_schedule/bulk_upsert_response.dart`:

```dart
class BulkUpsertAvailableDtResponse {
  int? code;
  String? message;
  List<BulkUpsertResult>? data;

  BulkUpsertAvailableDtResponse({this.code, this.message, this.data});

  factory BulkUpsertAvailableDtResponse.fromJson(Map<String, dynamic> json) =>
      BulkUpsertAvailableDtResponse(
        code: json['code'],
        message: json['message'],
        data: json['data'] == null
            ? null
            : (json['data'] as List)
                .map((e) => BulkUpsertResult.fromJson(Map<String, dynamic>.from(e)))
                .toList(),
      );
}

class BulkUpsertResult {
  String? serviceBranchId;
  bool? success;
  String? message;

  BulkUpsertResult({this.serviceBranchId, this.success, this.message});

  factory BulkUpsertResult.fromJson(Map<String, dynamic> json) => BulkUpsertResult(
        serviceBranchId: json['serviceBranchId'],
        success: json['success'],
        message: json['message'],
      );
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/practitioner_schedule/bulk_upsert_test.dart`
Expected: PASS

- [ ] **Step 5: Add `bulkUpsert` to the controller**

In `lib/controllers/service/service_branch_available_dt_controller.dart`, add imports:

```dart
import 'package:klinik_aurora_portal/models/practitioner_schedule/bulk_upsert_response.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/schedule_payload.dart';
```

and this static method after `update` (same pattern as the other methods):

```dart
  /// Batched create-or-update. Backend contract:
  /// POST admin/service-available-datetime/bulk-upsert
  /// {"items": [{"serviceBranchId": ..., "availableDatetimes": [...]}, ...]}
  /// Writes into the same records as create/update; response lists
  /// per-item success/failure.
  static Future<ApiResponse<BulkUpsertAvailableDtResponse>> bulkUpsert(
    BuildContext context,
    List<SchedulePayload> payloads,
  ) async {
    return ApiController()
        .call(
          context,
          method: Method.post,
          endpoint: 'admin/service-available-datetime/bulk-upsert',
          data: {
            'items': payloads.map((p) => p.toBulkItemJson()).toList(),
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: BulkUpsertAvailableDtResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }
```

- [ ] **Step 6: Create the saver with the fallback flag**

Create `lib/controllers/practitioner_schedule/practitioner_schedule_saver.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/bulk_upsert_response.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/schedule_payload.dart';

class SaveOutcome {
  final SchedulePayload payload;
  final bool success;
  final String? message;
  SaveOutcome({required this.payload, required this.success, this.message});
}

class PractitionerScheduleSaver {
  /// Flip to true once the backend ships
  /// POST admin/service-available-datetime/bulk-upsert.
  /// Until then, saving loops the existing create/update endpoints —
  /// identical outcome, N requests instead of 1.
  static bool useBulkUpsert = false;

  static Future<List<SaveOutcome>> save(BuildContext context, List<SchedulePayload> payloads) {
    return useBulkUpsert ? _saveBulk(context, payloads) : _saveIndividually(context, payloads);
  }

  static Future<List<SaveOutcome>> _saveBulk(BuildContext context, List<SchedulePayload> payloads) async {
    final response = await ServiceBranchAvailableDtController.bulkUpsert(context, payloads);
    if (!responseCode(response.code)) {
      final message = response.message ?? 'Bulk save failed';
      return [for (final p in payloads) SaveOutcome(payload: p, success: false, message: message)];
    }
    final results = <String?, BulkUpsertResult>{
      for (final r in response.data?.data ?? <BulkUpsertResult>[]) r.serviceBranchId: r,
    };
    return [
      for (final p in payloads)
        SaveOutcome(
          payload: p,
          // No per-item entry in the response means the whole batch succeeded.
          success: results[p.serviceBranchId]?.success ?? true,
          message: results[p.serviceBranchId]?.message,
        ),
    ];
  }

  static Future<List<SaveOutcome>> _saveIndividually(
    BuildContext context,
    List<SchedulePayload> payloads,
  ) async {
    final outcomes = <SaveOutcome>[];
    for (final p in payloads) {
      try {
        final r = p.existingRecordId != null
            ? await ServiceBranchAvailableDtController.update(
                context, p.existingRecordId!, p.serviceBranchId, p.availableDatetimes)
            : await ServiceBranchAvailableDtController.create(
                context, p.serviceBranchId, p.availableDatetimes);
        outcomes.add(SaveOutcome(payload: p, success: responseCode(r.code), message: r.message));
      } catch (e) {
        outcomes.add(SaveOutcome(payload: p, success: false, message: e.toString()));
      }
    }
    return outcomes;
  }
}
```

- [ ] **Step 7: Verify and commit**

Run: `flutter test test/practitioner_schedule/ && flutter analyze lib/controllers/practitioner_schedule/ lib/controllers/service/service_branch_available_dt_controller.dart lib/models/practitioner_schedule/`
Expected: tests PASS, analyze clean.

```bash
git add lib/models/practitioner_schedule/ lib/controllers/practitioner_schedule/practitioner_schedule_saver.dart lib/controllers/service/service_branch_available_dt_controller.dart test/practitioner_schedule/bulk_upsert_test.dart
git commit -m "feat: add bulk-upsert API contract and saver with per-service fallback"
```

---

### Task 6: Extract `WeeklyAvailabilityEditor` from `WeeklySlotGenerator`

**Files:**
- Create: `lib/views/widgets/calendar/weekly_availability_editor.dart`
- Modify: `lib/views/service/slot_generator.dart` (compose the editor; keep month/interval/generate/template concerns)

This is a refactor of existing, working UI. The rule: **move code verbatim wherever possible**; the only mechanical changes are listed in Step 2. Line numbers refer to `slot_generator.dart` as of commit `4cab8fe` (before this task).

- [ ] **Step 1: Create the editor controller and widget shell**

Create `lib/views/widgets/calendar/weekly_availability_editor.dart` with this skeleton (the `// MOVED:` markers are filled in Step 2):

```dart
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';

/// Holds the weekly pattern state so hosts (WeeklySlotGenerator, the
/// practitioner schedule wizard) can read/set the pattern programmatically.
class WeeklyAvailabilityEditorController extends ChangeNotifier {
  final Map<String, bool> selectedDays = {for (final d in weekDayKeys) d: false};
  final Map<String, List<TimeRange>> timeRanges = {for (final d in weekDayKeys) d: []};

  WeeklyPattern get pattern => WeeklyPattern(dayRanges: {
        for (final d in weekDayKeys)
          if (selectedDays[d] == true && timeRanges[d]!.isNotEmpty) d: List.of(timeRanges[d]!),
      });

  void setPattern(WeeklyPattern pattern) {
    for (final d in weekDayKeys) {
      final ranges = pattern.dayRanges[d] ?? [];
      selectedDays[d] = ranges.isNotEmpty;
      timeRanges[d] = List.of(ranges);
    }
    notifyListeners();
  }

  int get selectedDayCount => selectedDays.values.where((v) => v).length;

  bool get isValid {
    if (selectedDayCount == 0) return false;
    for (final d in weekDayKeys) {
      if (selectedDays[d] != true) continue;
      final ranges = timeRanges[d]!;
      if (ranges.isEmpty) return false;
      for (var i = 0; i < ranges.length; i++) {
        final r = ranges[i];
        final startM = r.start.hour * 60 + r.start.minute;
        final endM = r.end.hour * 60 + r.end.minute;
        if (startM > endM) return false;
        for (var j = i + 1; j < ranges.length; j++) {
          if (r.overlapsWith(ranges[j])) return false;
        }
      }
    }
    return true;
  }

  void refresh() => notifyListeners();
}

/// The weekly pattern editor: quick-select day buttons, the Master Timing
/// card (weekday/weekend + breaks), and the per-day range rows. Extracted
/// from WeeklySlotGenerator so the practitioner schedule wizard can reuse it.
class WeeklyAvailabilityEditor extends StatefulWidget {
  final WeeklyAvailabilityEditorController controller;

  /// When false the day list renders inside a shrink-wrapped column
  /// (host provides scrolling); when true it fills available height.
  final bool expandDayList;

  const WeeklyAvailabilityEditor({super.key, required this.controller, this.expandDayList = true});

  @override
  State<WeeklyAvailabilityEditor> createState() => _WeeklyAvailabilityEditorState();
}

class _WeeklyAvailabilityEditorState extends State<WeeklyAvailabilityEditor> {
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  Map<String, bool> get selectedDays => widget.controller.selectedDays;
  Map<String, List<TimeRange>> get timeRanges => widget.controller.timeRanges;

  String? copiedFromDay;
  bool isWeekdayMasterMode = true;
  bool hasMasterBreak = false;

  // MOVED: master timing state — slot_generator.dart lines 34-48
  //   (weekdayMasterStart/End, weekdayBreaks, weekendMasterStart/End,
  //    weekendBreaks, masterStart/masterEnd/masterBreaks getters)

  void _notify() {
    setState(() {});
    widget.controller.refresh();
  }

  // MOVED (verbatim, then apply the substitutions from Step 2):
  //   _selectAll, _selectWeekdays, _selectWeekends   (lines 64-93)
  //   _syncMasterToSelected, _getSegments            (lines 95-164)
  //   _clearDay                                      (lines 166-171)
  //   _showTimePicker                                (lines 174-191)
  //   _isBeforeOrEqual, _isBefore                    (lines 383-384)
  //   _copySlots, _pasteSlots                        (lines 391-402)
  //   _hasOverlap, _isValidRange                     (lines 404-414)
  //   _quickSelectBtn, _masterTimeField,
  //   _dayActionBtn, _compactTimeChip, _miniWarning  (lines 1044-1129, 1160-1174)

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final dayList = _dayList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _configAndMasterRow(), // MOVED: the "Config & Master" Row, lines 491-756,
            //   MINUS the Target Month and Slot Interval dropdowns (lines 511-554),
            //   which stay in WeeklySlotGenerator. Keep Quick Select Days + Master Timing.
            const SizedBox(height: 20),
            if (widget.expandDayList) Expanded(child: dayList) else dayList,
          ],
        );
      },
    );
  }

  Widget _dayList() {
    return ListView.builder(
      shrinkWrap: !widget.expandDayList,
      physics: widget.expandDayList ? null : const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      itemBuilder: (context, i) {
        // MOVED: day-row builder body, lines 763-964 (verbatim + substitutions)
        throw UnimplementedError('replaced by moved code');
      },
    );
  }
}
```

- [ ] **Step 2: Move the marked code and apply exactly these substitutions**

Fill every `// MOVED:` marker with the referenced code from `slot_generator.dart`, then apply these mechanical substitutions inside the moved code (and nothing else):

1. `rebuild.add(DateTime.now());` → `_notify();`
2. `setState(() { ... });` in moved methods stays, but any occurrence that ONLY wraps `timeRanges`/`selectedDays` mutations must also be followed by `widget.controller.refresh();` — simplest rule: replace `setState(() {` with `setState(() {` unchanged and append `widget.controller.refresh();` as the last statement of each moved method that mutates `selectedDays` or `timeRanges` (i.e. `_selectAll`, `_selectWeekdays`, `_selectWeekends`, `_syncMasterToSelected`, `_clearDay`, `_pasteSlots`).
3. In `_configAndMasterRow()`, delete the `Row` containing the two `_configDropdown` calls (Target Month / Slot Interval) and the `'Global Configuration'` label — the left card keeps only the "Quick Select Days" label + `Wrap` of `_quickSelectBtn`s. `_configDropdown` itself is NOT moved; it stays in `slot_generator.dart`.
4. `_selectedDayCount` getter is NOT moved — use `widget.controller.selectedDayCount` where needed.

- [ ] **Step 3: Refactor `WeeklySlotGenerator` to compose the editor**

In `lib/views/service/slot_generator.dart`:

1. Add imports:

```dart
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_helper.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/weekly_availability_editor.dart';
```

2. In `_WeeklySlotGeneratorState`, delete the moved state/fields/methods (everything listed in Step 1's MOVED markers, plus `selectedDays`, `timeRanges`, `rebuild`, `copiedFromDay`, `isWeekdayMasterMode`, `hasMasterBreak`, master timing fields/getters, `_formatTime`, `_parseTime`) and add:

```dart
  final WeeklyAvailabilityEditorController _editor = WeeklyAvailabilityEditorController();
```

3. Replace `initState` with:

```dart
  @override
  void initState() {
    super.initState();
    interval = widget.initInterval ?? 30;
    final now = DateTime.now();
    months = List.generate(4, (i) => DateTime(now.year, now.month + i));
    selectedMonth = months.first;
  }
```

4. Replace `_generateSlots` with:

```dart
  void _generateSlots() {
    final schedule = AvailabilitySchedule(
      pattern: _editor.pattern,
      availableFrom: DateTime(selectedMonth.year, selectedMonth.month, 1),
      availableUntil: DateTime(selectedMonth.year, selectedMonth.month + 1, 0),
    );
    final slots = expandSchedule(schedule, interval)
        .map((dt) => DateFormat('yyyy-MM-dd HH:mm:ss').format(dt))
        .toList();

    if (slots.isEmpty) {
      showDialogError(
        context,
        'No slots were generated. Please ensure at least one day is selected and has time ranges defined.',
      );
      return;
    }

    Navigator.pop(context, slots);
  }
```

(Behavior note, intentional: past dates within the current month are now excluded at generation time instead of at save time — `MultiTimeCalendarPage.filterPastMonths` previously stripped them at save anyway.)

5. Replace `_saveAllSlotsToPrefs` / `_loadAllSlotsFromPrefs` bodies to use the controller (storage format is identical to the old handwritten JSON, so previously saved templates still load):

```dart
  Future<void> _saveAllSlotsToPrefs() async {
    await prefs.setString('saved_weekly_slots', jsonEncode(_editor.pattern.toJson()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Timing template saved.'), backgroundColor: Color(0xFF16A34A)));
  }

  Future<void> _loadAllSlotsFromPrefs() async {
    try {
      final jsonString = prefs.getString('saved_weekly_slots');
      if (jsonString == null || jsonString.trim().isEmpty) {
        showDialogError(context, 'No saved timing template found.');
        return;
      }
      _editor.setPattern(WeeklyPattern.fromJson(jsonDecode(jsonString)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timing template loaded.')));
    } catch (e) {
      debugPrint('Error loading saved slots: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load timing template.')));
    }
  }
```

6. Replace the `build` method's `StreamBuilder` wrapper with a `ListenableBuilder(listenable: _editor, ...)`, compute `final canGenerate = _editor.isValid;`, keep the header row and the footer (`'$selectedCount day...'` uses `_editor.selectedDayCount`), keep the Global Configuration card containing ONLY the Target Month + Slot Interval `_configDropdown`s (Quick Select moved out), and replace the old Config/Master row + day-rows `Expanded` with:

```dart
            Expanded(child: WeeklyAvailabilityEditor(controller: _editor)),
```

placed between the config card and the footer.

- [ ] **Step 4: Verify — analyze, tests, and manual smoke test**

Run: `flutter analyze lib/views/service/slot_generator.dart lib/views/widgets/calendar/weekly_availability_editor.dart && flutter test test/practitioner_schedule/`
Expected: clean, PASS.

Manual smoke test (this is a refactor of a production flow — do not skip):
Run: `flutter run -d chrome` (or the project's usual device), open Services → any service → update slots → open the generator. Verify: quick-select buttons work, master timing pushes to days, ranges add/edit/copy/paste, template Save/Load works, Generate returns slots into the calendar, and Save on the calendar succeeds.

- [ ] **Step 5: Commit**

```bash
git add lib/views/widgets/calendar/weekly_availability_editor.dart lib/views/service/slot_generator.dart
git commit -m "refactor: extract WeeklyAvailabilityEditor from WeeklySlotGenerator"
```

---

### Task 7: Wizard shell + Step 1 (practitioner & target services)

**Files:**
- Create: `lib/views/practitioner_schedule/practitioner_schedule_wizard.dart`
- Create: `lib/views/practitioner_schedule/schedule_target.dart`

- [ ] **Step 1: Create the target model**

Create `lib/views/practitioner_schedule/schedule_target.dart`:

```dart
import 'package:klinik_aurora_portal/models/service_branch/service_branch_response.dart' as sb_model;

/// One active service-branch of the chosen practitioner type, with the
/// staff-editable gap. gapMinutes defaults from serviceTime but is
/// deliberately editable: branches stretch e.g. 45-min services to 60-min
/// gaps to buffer walk-ins and late arrivals. Editing it never changes
/// the service's serviceTime.
class ScheduleTarget {
  final sb_model.Data service;
  bool selected;
  int gapMinutes;

  /// Loaded before the timing step: the service's current slot record.
  String? existingRecordId;
  List<String> existingDatetimes;
  bool existingLoaded;

  ScheduleTarget({
    required this.service,
    required this.gapMinutes,
    this.selected = true,
    this.existingRecordId,
    List<String>? existingDatetimes,
    this.existingLoaded = false,
  }) : existingDatetimes = existingDatetimes ?? [];
}
```

- [ ] **Step 2: Create the wizard with Step 1 implemented**

Create `lib/views/practitioner_schedule/practitioner_schedule_wizard.dart`:

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_helper.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_saver.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/practitioner_schedule/schedule_payload.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_help.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_target.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_step_timing.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_step_confirm.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/weekly_availability_editor.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

const List<int> practitionerTypeValues = [1, 2, 3, 4, 5]; // see doctorType() in global.dart

class PractitionerScheduleWizard extends StatefulWidget {
  /// Branch of the logged-in staff; null (HQ/superadmin) shows a branch picker.
  final String? branchId;
  const PractitionerScheduleWizard({super.key, this.branchId});

  @override
  State<PractitionerScheduleWizard> createState() => _PractitionerScheduleWizardState();
}

class _PractitionerScheduleWizardState extends State<PractitionerScheduleWizard> {
  int _step = 0; // 0 = practitioner & services, 1 = timing, 2 = confirm
  bool _saving = false;

  String? _branchId;
  List<branch_model.Data> _branches = [];
  int? _doctorTypeValue;
  List<ScheduleTarget> _targets = [];
  bool _loadingTargets = false;

  final WeeklyAvailabilityEditorController _editor = WeeklyAvailabilityEditorController();
  late DateTime _availableFrom;
  late DateTime _availableUntil;
  Map<String, List<TimeRange>?> _dateOverrides = {};

  List<SaveOutcome>? _outcomes;

  @override
  void initState() {
    super.initState();
    _branchId = widget.branchId;
    final now = DateTime.now();
    _availableFrom = DateTime(now.year, now.month, now.day);
    _availableUntil = DateTime(now.year, now.month + 3, 0); // end of month +2
    if (_branchId == null) _loadBranches();
  }

  AvailabilitySchedule get schedule => AvailabilitySchedule(
        pattern: _editor.pattern,
        availableFrom: _availableFrom,
        availableUntil: _availableUntil,
        dateOverrides: _dateOverrides,
      );

  List<ScheduleTarget> get _selectedTargets => _targets.where((t) => t.selected).toList();

  String get _prefsKey => 'practitioner_pattern_${_branchId}_$_doctorTypeValue';

  // ─── Data loading ───

  Future<void> _loadBranches() async {
    final result = await BranchController.getAll(context, 1, 100);
    if (!mounted) return;
    setState(() => _branches = result.data?.data ?? []);
  }

  Future<void> _loadTargets() async {
    if (_branchId == null || _doctorTypeValue == null) return;
    setState(() {
      _loadingTargets = true;
      _targets = [];
    });
    final result = await ServiceBranchController.getAll(context, 1, 100, branchId: _branchId);
    if (!mounted) return;
    final services = (result.data?.data ?? [])
        .where((s) => s.serviceBranchStatus == 1 && s.doctorType == _doctorTypeValue)
        .toList();
    setState(() {
      _loadingTargets = false;
      _targets = [
        for (final s in services)
          ScheduleTarget(service: s, gapMinutes: parseServiceTimeToMinutes(s.serviceTime)),
      ];
    });
    _restoreSavedState();
  }

  /// Loads existing slot records for selected targets (needed for the
  /// replace warnings on the timing step and the merge on save).
  Future<bool> _loadExistingSlots() async {
    showLoading();
    try {
      for (final target in _selectedTargets.where((t) => !t.existingLoaded)) {
        final result = await ServiceBranchAvailableDtController.get(
          context, 1, 100,
          serviceBranchId: target.service.serviceBranchId,
        );
        if (!responseCode(result.code)) continue;
        final record = result.data?.data?.isNotEmpty == true ? result.data!.data!.first : null;
        target.existingRecordId = record?.serviceBranchAvailableDatetimeId;
        target.existingDatetimes = record?.availableDatetimes ?? [];
        target.existingLoaded = true;
      }
      return true;
    } finally {
      dismissLoading();
    }
  }

  // ─── Pattern persistence (device-local, per branch + type) ───

  void _restoreSavedState() {
    try {
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.trim().isEmpty) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final saved = AvailabilitySchedule.fromJson(Map<String, dynamic>.from(data['schedule']));
      _editor.setPattern(saved.pattern);
      final today = DateTime.now();
      if (!saved.availableUntil.isBefore(DateTime(today.year, today.month, today.day))) {
        _availableFrom = saved.availableFrom;
        _availableUntil = saved.availableUntil;
        _dateOverrides = saved.dateOverrides;
      }
      final gaps = Map<String, dynamic>.from(data['gaps'] ?? {});
      for (final target in _targets) {
        final savedGap = gaps[target.service.serviceBranchId];
        if (savedGap is int && savedGap > 0) target.gapMinutes = savedGap;
      }
      setState(() {});
    } catch (e) {
      debugPrint('Failed to restore practitioner schedule state: $e');
    }
  }

  Future<void> _persistState() async {
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'schedule': schedule.toJson(),
        'gaps': {for (final t in _targets) t.service.serviceBranchId ?? '': t.gapMinutes},
      }),
    );
  }

  // ─── Navigation & save ───

  String? get _stepBlockReason {
    if (_step == 0) {
      if (_branchId == null) return 'Select a branch first.';
      if (_doctorTypeValue == null) return 'Select a practitioner type first.';
      if (_selectedTargets.isEmpty) return 'Tick at least one service.';
      if (_selectedTargets.any((t) => t.gapMinutes <= 0)) return 'Every ticked service needs a gap above 0 minutes.';
      return null;
    }
    if (_step == 1) {
      if (_availableUntil.isBefore(_availableFrom)) return '"Available until" must be after "Available from".';
      final today = DateTime.now();
      if (_availableUntil.isBefore(DateTime(today.year, today.month, today.day))) {
        return 'The selected period is entirely in the past.';
      }
      if (!_editor.isValid) return 'Set at least one day with valid, non-overlapping hours.';
      if (_selectedTargets.every((t) => expandSchedule(schedule, t.gapMinutes).isEmpty)) {
        return 'This configuration generates no slots.';
      }
      return null;
    }
    return null;
  }

  Future<void> _next() async {
    final reason = _stepBlockReason;
    if (reason != null) {
      showDialogError(context, reason);
      return;
    }
    if (_step == 0) {
      final ok = await _loadExistingSlots();
      if (!ok || !mounted) return;
    }
    setState(() => _step++);
  }

  Future<void> _save({bool retryFailedOnly = false}) async {
    final targetsToSave = retryFailedOnly
        ? _selectedTargets
            .where((t) => _outcomes!
                .any((o) => !o.success && o.payload.serviceBranchId == t.service.serviceBranchId))
            .toList()
        : _selectedTargets;
    final payloads = [
      for (final t in targetsToSave)
        SchedulePayload(
          serviceBranchId: t.service.serviceBranchId ?? '',
          serviceName: t.service.serviceName ?? '',
          existingRecordId: t.existingRecordId,
          availableDatetimes: mergeReplacePeriod(
            existing: t.existingDatetimes,
            replacement: toUtcIsoList(expandSchedule(schedule, t.gapMinutes)),
            from: _availableFrom,
            until: _availableUntil,
          ),
        ),
    ];

    setState(() => _saving = true);
    await _persistState();
    final outcomes = await PractitionerScheduleSaver.save(context, payloads);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (retryFailedOnly && _outcomes != null) {
        final retried = {for (final o in outcomes) o.payload.serviceBranchId: o};
        _outcomes = [for (final o in _outcomes!) retried[o.payload.serviceBranchId] ?? o];
      } else {
        _outcomes = outcomes;
      }
    });
  }

  // ─── UI ───

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 900,
          height: 720,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 16),
              _stepIndicator(),
              const SizedBox(height: 16),
              Expanded(child: _stepBody()),
              const SizedBox(height: 16),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: secondaryColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.schedule_rounded, color: secondaryColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Practitioner Schedule', style: AppTypography.displayMedium(context)),
              Text(
                'Set availability once, apply to every service of that practitioner.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => showScheduleHelp(context, _step),
          icon: Icon(Icons.help_outline_rounded, size: 16, color: Colors.orange[700]),
          label: Text('Help', style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.bold)),
        ),
        if (!_saving) CloseButton(onPressed: () => Navigator.pop(context, _outcomes != null)),
      ],
    );
  }

  Widget _stepIndicator() {
    const labels = ['1. Practitioner & services', '2. Availability timing', '3. Confirm & apply'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: i == _step ? secondaryColor : (i < _step ? secondaryColor.withAlpha(30) : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: i == _step ? Colors.white : (i < _step ? secondaryColor : Colors.grey[500]),
              ),
            ),
          ),
          if (i < labels.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
            ),
        ],
      ],
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _targetsStep();
      case 1:
        return ScheduleStepTiming(
          editor: _editor,
          availableFrom: _availableFrom,
          availableUntil: _availableUntil,
          dateOverrides: _dateOverrides,
          targets: _selectedTargets,
          buildSchedule: () => schedule,
          onPeriodChanged: (from, until) => setState(() {
            _availableFrom = from;
            _availableUntil = until;
          }),
          onOverridesChanged: () => setState(() {}),
        );
      default:
        return ScheduleStepConfirm(
          targets: _selectedTargets,
          buildSchedule: () => schedule,
          doctorTypeLabel: doctorType(_doctorTypeValue),
          outcomes: _outcomes,
          saving: _saving,
          onRetryFailed: () => _save(retryFailedOnly: true),
        );
    }
  }

  Widget _targetsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.branchId == null) ...[
                Expanded(child: _branchDropdown()),
                const SizedBox(width: 16),
              ],
              Expanded(child: _typeDropdown()),
            ],
          ),
          const SizedBox(height: 20),
          if (_loadingTargets)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_doctorTypeValue == null)
            _emptyHint('Select a practitioner type to list its active services.')
          else if (_targets.isEmpty)
            _emptyHint('No active ${doctorType(_doctorTypeValue)} services at this branch.')
          else
            _targetList(),
        ],
      ),
    );
  }

  Widget _branchDropdown() {
    return _labeledDropdown<String>(
      label: 'Branch',
      value: _branchId,
      items: [
        for (final b in _branches)
          DropdownMenuItem(value: b.branchId, child: Text(b.branchName ?? '', style: const TextStyle(fontSize: 13))),
      ],
      onChanged: (v) {
        setState(() => _branchId = v);
        _loadTargets();
      },
    );
  }

  Widget _typeDropdown() {
    return _labeledDropdown<int>(
      label: 'Practitioner type',
      value: _doctorTypeValue,
      items: [
        for (final v in practitionerTypeValues)
          DropdownMenuItem(value: v, child: Text(doctorType(v), style: const TextStyle(fontSize: 13))),
      ],
      onChanged: (v) {
        setState(() => _doctorTypeValue = v);
        _loadTargets();
      },
    );
  }

  Widget _labeledDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(value: value, isExpanded: true, items: items, onChanged: onChanged),
          ),
        ),
      ],
    );
  }

  Widget _targetList() {
    final allSelected = _targets.every((t) => t.selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${_targets.length} active ${doctorType(_doctorTypeValue)} service${_targets.length == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() {
                for (final t in _targets) {
                  t.selected = !allSelected;
                }
              }),
              child: Text(allSelected ? 'Untick all' : 'Tick all', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: const Text(
            'Gap = time between appointment slots. It starts from each service\'s duration, '
            'but you can widen it (e.g. 45 → 60 minutes) to leave room for walk-in patients '
            'and late arrivals. Changing it here never changes the service itself.',
            style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
          ),
        ),
        for (final target in _targets)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: target.selected ? Colors.white : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: target.selected ? secondaryColor.withAlpha(100) : const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: target.selected,
                  activeColor: secondaryColor,
                  onChanged: (v) => setState(() => target.selected = v ?? false),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(target.service.serviceName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('Duration: ${target.service.serviceTime ?? '-'}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                const Text('Gap:', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: const [15, 30, 45, 60, 90, 120].contains(target.gapMinutes) ? target.gapMinutes : null,
                    hint: Text('${target.gapMinutes} min', style: const TextStyle(fontSize: 12)),
                    items: const [15, 30, 45, 60, 90, 120]
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text('$m min', style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: target.selected ? (v) => setState(() => target.gapMinutes = v!) : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _emptyHint(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.medical_services_outlined, size: 56, color: Colors.grey[200]),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    final done = _outcomes != null && _outcomes!.every((o) => o.success);
    return Row(
      children: [
        if (_step > 0 && _outcomes == null)
          OutlinedButton(
            onPressed: _saving ? null : () => setState(() => _step--),
            child: const Text('Back'),
          ),
        const Spacer(),
        if (_stepBlockReason != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(_stepBlockReason!, style: const TextStyle(fontSize: 12, color: Color(0xFF9A3412))),
          ),
        if (_step < 2)
          ElevatedButton(
            onPressed: _stepBlockReason == null ? _next : null,
            style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: Colors.white),
            child: const Text('Next'),
          )
        else if (done)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: Colors.white),
            child: const Text('Done'),
          )
        else
          ElevatedButton(
            onPressed: _saving || _outcomes != null ? null : () => _save(),
            style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: Colors.white),
            child: Text(_saving ? 'Applying…' : 'Apply schedule'),
          ),
      ],
    );
  }
}
```

Note: this file references `ScheduleStepTiming`, `ScheduleStepConfirm`, and `showScheduleHelp`, which are created in Tasks 8–10. To keep this task compilable on its own, create the two step files as minimal placeholders in this task (they are fully implemented in Tasks 8–9):

`lib/views/practitioner_schedule/schedule_step_timing.dart` (placeholder, replaced in Task 8):

```dart
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_target.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/weekly_availability_editor.dart';

class ScheduleStepTiming extends StatefulWidget {
  final WeeklyAvailabilityEditorController editor;
  final DateTime availableFrom;
  final DateTime availableUntil;
  final Map<String, List<TimeRange>?> dateOverrides;
  final List<ScheduleTarget> targets;
  final AvailabilitySchedule Function() buildSchedule;
  final void Function(DateTime from, DateTime until) onPeriodChanged;
  final VoidCallback onOverridesChanged;

  const ScheduleStepTiming({
    super.key,
    required this.editor,
    required this.availableFrom,
    required this.availableUntil,
    required this.dateOverrides,
    required this.targets,
    required this.buildSchedule,
    required this.onPeriodChanged,
    required this.onOverridesChanged,
  });

  @override
  State<ScheduleStepTiming> createState() => _ScheduleStepTimingState();
}

class _ScheduleStepTimingState extends State<ScheduleStepTiming> {
  @override
  Widget build(BuildContext context) => const Center(child: Text('Timing step — Task 8'));
}
```

`lib/views/practitioner_schedule/schedule_step_confirm.dart` (placeholder, replaced in Task 9):

```dart
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_saver.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_target.dart';

class ScheduleStepConfirm extends StatelessWidget {
  final List<ScheduleTarget> targets;
  final AvailabilitySchedule Function() buildSchedule;
  final String doctorTypeLabel;
  final List<SaveOutcome>? outcomes;
  final bool saving;
  final VoidCallback onRetryFailed;

  const ScheduleStepConfirm({
    super.key,
    required this.targets,
    required this.buildSchedule,
    required this.doctorTypeLabel,
    required this.outcomes,
    required this.saving,
    required this.onRetryFailed,
  });

  @override
  Widget build(BuildContext context) => const Center(child: Text('Confirm step — Task 9'));
}
```

`lib/views/practitioner_schedule/schedule_help.dart` (placeholder, replaced in Task 10):

```dart
import 'package:flutter/material.dart';

void showScheduleHelp(BuildContext context, int step) {}
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/views/practitioner_schedule/`
Expected: clean (unused-variable infos acceptable in placeholders).

- [ ] **Step 4: Commit**

```bash
git add lib/views/practitioner_schedule/
git commit -m "feat: practitioner schedule wizard shell with targets step"
```

---

### Task 8: Step 2 — timing (period, pattern editor, override calendar, load-from-existing)

**Files:**
- Create: `lib/views/practitioner_schedule/date_override_calendar.dart`
- Rewrite: `lib/views/practitioner_schedule/schedule_step_timing.dart`

- [ ] **Step 1: Create the override calendar**

Create `lib/views/practitioner_schedule/date_override_calendar.dart`:

```dart
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

  Future<void> _editDate(DateTime date) async {
    final key = dateKey(date);
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(DateFormat('EEEE, d MMM yyyy').format(date), style: const TextStyle(fontSize: 15)),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'exclude'),
            child: const Text('No slots this day (holiday / leave)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'custom'),
            child: const Text('Custom hours for this day only…'),
          ),
          if (widget.dateOverrides.containsKey(key))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'reset'),
              child: const Text('Reset to weekly pattern'),
            ),
        ],
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
      widget.dateOverrides[key] = edited;
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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, working),
              child: const Text('Save'),
            ),
          ],
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
```

- [ ] **Step 2: Implement the timing step**

Replace the entire contents of `lib/views/practitioner_schedule/schedule_step_timing.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_helper.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/date_override_calendar.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_target.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/weekly_availability_editor.dart';

class ScheduleStepTiming extends StatefulWidget {
  final WeeklyAvailabilityEditorController editor;
  final DateTime availableFrom;
  final DateTime availableUntil;
  final Map<String, List<TimeRange>?> dateOverrides;
  final List<ScheduleTarget> targets;
  final AvailabilitySchedule Function() buildSchedule;
  final void Function(DateTime from, DateTime until) onPeriodChanged;
  final VoidCallback onOverridesChanged;

  const ScheduleStepTiming({
    super.key,
    required this.editor,
    required this.availableFrom,
    required this.availableUntil,
    required this.dateOverrides,
    required this.targets,
    required this.buildSchedule,
    required this.onPeriodChanged,
    required this.onOverridesChanged,
  });

  @override
  State<ScheduleStepTiming> createState() => _ScheduleStepTimingState();
}

class _ScheduleStepTimingState extends State<ScheduleStepTiming> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: period + pattern editor
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _periodRow(),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: widget.editor,
                  builder: (context, _) =>
                      WeeklyAvailabilityEditor(controller: widget.editor, expandDayList: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Right: override calendar + per-service preview
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Calendar preview & day overrides',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _loadFromExistingService,
                      icon: const Icon(Icons.download_rounded, size: 14),
                      label: const Text('Load from existing service', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                Text('Tap a date to exclude it (holiday, leave) or set custom hours.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 8),
                ListenableBuilder(
                  listenable: widget.editor,
                  builder: (context, _) => DateOverrideCalendar(
                    from: widget.availableFrom,
                    until: widget.availableUntil,
                    pattern: () => widget.editor.pattern,
                    dateOverrides: widget.dateOverrides,
                    onChanged: widget.onOverridesChanged,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Slots that will be created', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ListenableBuilder(listenable: widget.editor, builder: (context, _) => _previewList()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _periodRow() {
    return Row(
      children: [
        Expanded(child: _dateField('Available from', widget.availableFrom, (picked) {
          widget.onPeriodChanged(picked, widget.availableUntil);
        })),
        const SizedBox(width: 12),
        Expanded(child: _dateField('Available until (expiry)', widget.availableUntil, (picked) {
          widget.onPeriodChanged(widget.availableFrom, picked);
        })),
      ],
    );
  }

  Widget _dateField(String label, DateTime value, ValueChanged<DateTime> onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value.isBefore(now) ? now : value,
              firstDate: DateTime(now.year, now.month, now.day),
              lastDate: DateTime(now.year + 1, 12, 31),
            );
            if (picked != null) onPicked(DateTime(picked.year, picked.month, picked.day));
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: secondaryColor),
                const SizedBox(width: 8),
                Text(DateFormat('d MMM yyyy').format(value),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _previewList() {
    final schedule = widget.buildSchedule();
    final periodLabel =
        '${DateFormat('d MMM').format(widget.availableFrom)} – ${DateFormat('d MMM').format(widget.availableUntil)}';
    return Column(
      children: [
        for (final target in widget.targets)
          Builder(builder: (context) {
            final count = expandSchedule(schedule, target.gapMinutes).length;
            final hasExistingInPeriod = target.existingDatetimes.any((iso) {
              final dt = DateTime.tryParse(iso)?.toLocal();
              if (dt == null) return false;
              return !dt.isBefore(widget.availableFrom) &&
                  dt.isBefore(DateTime(
                      widget.availableUntil.year, widget.availableUntil.month, widget.availableUntil.day + 1));
            });
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(target.service.serviceName ?? '',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      Text('${target.gapMinutes} min · $count slots',
                          style: const TextStyle(fontSize: 12, color: secondaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (hasExistingInPeriod)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFEA580C)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Existing $periodLabel slots (including manual per-service edits) will be replaced.',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF9A3412)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _loadFromExistingService() async {
    final candidates = widget.targets.where((t) => t.existingDatetimes.isNotEmpty).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('None of the selected services have existing slots to load from.')),
      );
      return;
    }
    final chosen = await showDialog<ScheduleTarget>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rebuild schedule from…', style: TextStyle(fontSize: 15)),
        children: [
          for (final t in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Text('${t.service.serviceName} (${t.existingDatetimes.length} slots)'),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    final reconstructed = reconstructSchedule(
      chosen.existingDatetimes,
      from: widget.availableFrom,
      until: widget.availableUntil,
      gapMinutes: chosen.gapMinutes,
    );
    widget.editor.setPattern(reconstructed.pattern);
    widget.dateOverrides.clear();
    widget.onOverridesChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'Schedule rebuilt from "${chosen.service.serviceName}". Timings are inferred — review before applying.'),
      backgroundColor: const Color(0xFFEA580C),
    ));
  }
}
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/views/practitioner_schedule/`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add lib/views/practitioner_schedule/
git commit -m "feat: wizard timing step with period, pattern editor and day overrides"
```

---

### Task 9: Step 3 — confirm, apply, results & retry

**Files:**
- Rewrite: `lib/views/practitioner_schedule/schedule_step_confirm.dart`

- [ ] **Step 1: Implement the confirm step**

Replace the entire contents of `lib/views/practitioner_schedule/schedule_step_confirm.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_helper.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_saver.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_target.dart';

class ScheduleStepConfirm extends StatelessWidget {
  final List<ScheduleTarget> targets;
  final AvailabilitySchedule Function() buildSchedule;
  final String doctorTypeLabel;
  final List<SaveOutcome>? outcomes;
  final bool saving;
  final VoidCallback onRetryFailed;

  const ScheduleStepConfirm({
    super.key,
    required this.targets,
    required this.buildSchedule,
    required this.doctorTypeLabel,
    required this.outcomes,
    required this.saving,
    required this.onRetryFailed,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = buildSchedule();
    final periodLabel =
        '${DateFormat('d MMM yyyy').format(schedule.availableFrom)} – ${DateFormat('d MMM yyyy').format(schedule.availableUntil)}';
    final excludedCount = schedule.dateOverrides.values.where((v) => v == null).length;
    final customCount = schedule.dateOverrides.values.where((v) => v != null).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$doctorTypeLabel schedule · $periodLabel',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF166534))),
                const SizedBox(height: 4),
                Text(
                  '${targets.length} service${targets.length == 1 ? '' : 's'} will be updated. '
                  'Existing slots inside this period will be replaced; slots outside it are kept.'
                  '${excludedCount > 0 ? ' $excludedCount date${excludedCount == 1 ? '' : 's'} excluded.' : ''}'
                  '${customCount > 0 ? ' $customCount date${customCount == 1 ? '' : 's'} with custom hours.' : ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final target in targets) _row(context, target, schedule),
          if (outcomes != null && outcomes!.any((o) => !o.success)) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: saving ? null : onRetryFailed,
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFEA580C)),
              label: const Text('Retry failed services', style: TextStyle(color: Color(0xFFEA580C))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ScheduleTarget target, AvailabilitySchedule schedule) {
    final count = expandSchedule(schedule, target.gapMinutes).length;
    SaveOutcome? outcome;
    if (outcomes != null) {
      for (final o in outcomes!) {
        if (o.payload.serviceBranchId == target.service.serviceBranchId) outcome = o;
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: outcome == null
              ? const Color(0xFFE5E7EB)
              : (outcome.success ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
        ),
      ),
      child: Row(
        children: [
          if (outcome != null)
            Icon(
              outcome.success ? Icons.check_circle_rounded : Icons.error_rounded,
              size: 18,
              color: outcome.success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            )
          else
            const Icon(Icons.radio_button_unchecked_rounded, size: 18, color: Color(0xFFD1D5DB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(target.service.serviceName ?? '',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (outcome != null && !outcome.success)
                  Text(outcome.message ?? 'Failed to save.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
              ],
            ),
          ),
          Text('${target.gapMinutes} min gap · $count slots',
              style: const TextStyle(fontSize: 12, color: secondaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/views/practitioner_schedule/`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/views/practitioner_schedule/schedule_step_confirm.dart
git commit -m "feat: wizard confirm step with per-service outcomes and retry"
```

---

### Task 10: Entry point, help guides, staff guide doc, end-to-end verification

**Files:**
- Rewrite: `lib/views/practitioner_schedule/schedule_help.dart`
- Modify: `lib/views/service/service_homepage.dart` (toolbar in `_topBar()`, lines 107–183)
- Create: `docs/guides/practitioner-schedule.md`

- [ ] **Step 1: Implement the per-step help dialogs**

Replace the entire contents of `lib/views/practitioner_schedule/schedule_help.dart` (same visual pattern as `_showHelpGuide`/`_guideStep` in `slot_generator.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

void showScheduleHelp(BuildContext context, int step) {
  final content = switch (step) {
    0 => const [
        (1, 'Pick the practitioner', 'Choose who this schedule is for: Doctor, Sonographer, Therapist, Spa Therapist, or Dietitian. All of that practitioner\'s active services at your branch appear automatically.'),
        (2, 'Check the gap for each service', 'The gap is the time between appointment slots. It starts from the service\'s duration, but you can widen it — for example set a 45-minute service to 60-minute gaps to leave room for walk-in patients and late arrivals.'),
        (3, 'Untick services you don\'t want to change', 'Only ticked services will get the new schedule. Everything else is left exactly as it is.'),
      ],
    1 => const [
        (1, 'Set the period', '"Available from" and "Available until" are the dates the practitioner is available. Only slots inside this period are created or replaced — anything outside is untouched.'),
        (2, 'Set the weekly hours', 'Tick working days and set hours and breaks. Use Master Timing to fill several days at once.'),
        (3, 'Handle special days', 'On the calendar, tap a date to mark it as no-slots (holiday, leave) or give it custom hours for that day only.'),
        (4, 'Check the preview', 'The right panel shows how many slots each service gets. An orange warning means that service already has slots in this period — they will be replaced when you apply.'),
        (5, 'Rebuild from existing slots', 'On a new computer the saved pattern may be missing. "Load from existing service" rebuilds the schedule from a service\'s current slots so you can edit instead of starting over.'),
      ],
    _ => const [
        (1, 'Review before applying', 'This page lists every service that will be updated, its gap, and how many slots it gets. Nothing is saved until you press "Apply schedule".'),
        (2, 'What applying does', 'For each ticked service: slots inside the period are replaced with the new schedule; slots outside the period are kept.'),
        (3, 'If something fails', 'Each service shows a green tick or a red error. Press "Retry failed services" to resend only the ones that failed.'),
      ],
  };

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline_rounded, color: Colors.orange[700], size: 24),
                const SizedBox(width: 12),
                Text('How this step works', style: AppTypography.displayMedium(context)),
              ],
            ),
            const SizedBox(height: 24),
            for (final (number, title, description) in content)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
                      child: Text('$number',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(description,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: secondaryColor.withAlpha(20),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Got it!', style: TextStyle(fontWeight: FontWeight.bold, color: secondaryColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 2: Add the toolbar entry point**

In `lib/views/service/service_homepage.dart`, add the import:

```dart
import 'package:klinik_aurora_portal/views/practitioner_schedule/practitioner_schedule_wizard.dart';
```

In `_topBar()`, insert this immediately after the search field's `const SizedBox(width: 12),` (line 136) — before the `if (isSuperAdmin)` block, so both roles see it:

```dart
          _toolbarButton(
            icon: Icons.schedule_rounded,
            label: 'Practitioner Schedule',
            color: secondaryColor,
            onTap: _openPractitionerSchedule,
          ),
          const SizedBox(width: 8),
```

Add this method to the state class (near `_handleAdminMenuSelection`):

```dart
  void _openPractitionerSchedule() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PractitionerScheduleWizard(
        branchId: context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
      ),
    ).then((changed) {
      if (changed == true) filtering();
    });
  }
```

(If `secondaryColor` is not already imported in this file, add `import 'package:klinik_aurora_portal/config/color.dart';`.)

- [ ] **Step 3: Write the staff guide**

Create `docs/guides/practitioner-schedule.md`:

```markdown
# Practitioner Schedule — Staff Guide

Set a practitioner's availability once and apply it to every service they
handle at your branch, instead of configuring each service one by one.

**Where:** Services page → **Practitioner Schedule** button (top toolbar).

## Step 1 — Practitioner & services

1. Pick the practitioner type (Doctor, Sonographer, Therapist, Spa Therapist, Dietitian).
   <!-- screenshot: step1-type.png -->
2. All active services of that type at your branch are listed and ticked.
   Untick any service you don't want to change.
3. Check each service's **gap** — the time between appointment slots.
   It starts from the service duration, but you can widen it (e.g. 45 → 60
   minutes) to leave room for walk-in patients and late arrivals. This never
   changes the service's actual duration.

## Step 2 — Availability timing

1. Set **Available from** and **Available until** — the practitioner's
   availability period. Only slots inside this period are created or
   replaced; anything outside is untouched.
   <!-- screenshot: step2-period.png -->
2. Set the weekly hours: tick working days, set hours and breaks.
   Master Timing fills several days at once.
3. On the calendar preview, tap any date to mark it **No slots** (public
   holiday, leave) or give it **custom hours** for that day only.
4. Check the preview on the right: each service's slot count, and an orange
   warning wherever existing slots will be replaced.
5. New computer / pattern missing? Use **Load from existing service** to
   rebuild the schedule from a service's current slots, then edit it.

## Step 3 — Confirm & apply

1. Review the summary: every service, its gap, its slot count.
2. Press **Apply schedule**. Each service shows a green tick when saved.
3. If any service shows a red error, press **Retry failed services** —
   only the failed ones are resent.

## Good to know

- **Replacing:** applying a schedule replaces each ticked service's slots
  *inside the chosen period* — including one-off manual edits made on the
  per-service calendar. Slots outside the period are always kept.
- **Editing later:** reopen Practitioner Schedule — your last pattern for
  that branch + practitioner is preloaded. Adjust and apply again.
- **One-off fixes for a single service** (e.g. close this Friday for one
  service only): use the existing per-service calendar (service menu →
  update slots), not this wizard.
- **Different slot times per service are normal:** a 45-minute-gap service
  gets 9:00 / 9:45 / 10:30 while a 60-minute-gap service gets
  9:00 / 10:00 / 11:00 from the same working hours.
```

- [ ] **Step 4: Full verification**

Run: `flutter analyze && flutter test test/practitioner_schedule/`
Expected: no new analyzer issues vs the pre-Task-1 baseline; all tests PASS.

Manual end-to-end checklist (run the app):
1. Services page shows the "Practitioner Schedule" button; it opens the wizard.
2. Step 1: picking "Doctor" lists only active doctor services; gap editable per row; "Next" blocked until valid (reason shown next to the button).
3. Step 2: period pickers work; pattern editor works; excluding a date turns it red and drops its slots from the preview counts; a service with existing slots in the period shows the amber replace warning.
4. Step 3: summary matches; "Apply schedule" saves (fallback loop path — `useBulkUpsert` is false), per-service green ticks appear; "Done" closes and the service list refreshes.
5. Verify the result via an affected service's per-service calendar: new slots in the period, pre-existing slots outside the period untouched.
6. Reopen the wizard for the same branch + type: pattern, overrides, and gaps are preloaded.
7. "Load from existing service" reconstructs a sensible pattern from one of the just-saved services.
8. Regression: the per-service calendar + WeeklySlotGenerator still work end-to-end (Task 6 smoke test repeated once against final code).

- [ ] **Step 5: Commit**

```bash
git add lib/views/practitioner_schedule/schedule_help.dart lib/views/service/service_homepage.dart docs/guides/practitioner-schedule.md
git commit -m "feat: practitioner schedule entry point, in-app help and staff guide"
```

---

## Backend handoff (separate codebase — give this to the backend team)

New endpoint (frontend already calls it once `PractitionerScheduleSaver.useBulkUpsert` is flipped to `true`):

```
POST admin/service-available-datetime/bulk-upsert
Authorization: Bearer <admin token>

Request:
{
  "items": [
    { "serviceBranchId": "<uuid>", "availableDatetimes": ["2026-08-03T01:00:00.000Z", ...] },
    ...
  ]
}

Behavior (per item, same outcome as the existing create/update endpoints):
- If a service_branch_available_datetime record exists for serviceBranchId → update its availableDatetimes.
- Otherwise → create one.
- Run the batch in one transaction where practical.
- MUST write to the same table/records as the existing create/update —
  the patient booking flow reads through admin/service-available-datetime/available unchanged.

Response:
{
  "code": 200,
  "message": "ok",
  "data": [
    { "serviceBranchId": "<uuid>", "success": true },
    { "serviceBranchId": "<uuid>", "success": false, "message": "<reason>" }
  ]
}
```

Until this ships, the feature works via the per-service fallback loop — no frontend release is blocked on it.
