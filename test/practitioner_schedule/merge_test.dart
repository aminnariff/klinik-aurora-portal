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
