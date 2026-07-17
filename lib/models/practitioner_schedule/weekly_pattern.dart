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
