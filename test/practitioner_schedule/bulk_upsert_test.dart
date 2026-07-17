import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_saver.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/bulk_upsert_response.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/schedule_payload.dart';

SchedulePayload payload(String id) => SchedulePayload(
      serviceBranchId: id,
      serviceName: 'Service $id',
      existingRecordId: null,
      availableDatetimes: const [],
    );

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

  test('SchedulePayload pins the resolved record id when it has one', () {
    final payload = SchedulePayload(
      serviceBranchId: 'sb-1',
      serviceName: 'Consultation',
      existingRecordId: 'rec-9',
      availableDatetimes: const [],
    );
    expect(payload.toBulkItemJson(), {
      'serviceBranchId': 'sb-1',
      'serviceBranchAvailableDatetimeId': 'rec-9',
      'availableDatetimes': <String>[],
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

  group('PractitionerScheduleSaver.mapBulkResults', () {
    test('maps matched per-item successes and failures', () {
      final outcomes = PractitionerScheduleSaver.mapBulkResults(
        [payload('sb-1'), payload('sb-2')],
        BulkUpsertAvailableDtResponse(data: [
          BulkUpsertResult(serviceBranchId: 'sb-1', success: true),
          BulkUpsertResult(serviceBranchId: 'sb-2', success: false, message: 'not found'),
        ]),
      );
      expect(outcomes[0].success, isTrue);
      expect(outcomes[1].success, isFalse);
      expect(outcomes[1].message, 'not found');
    });

    test('fails closed when a payload has no per-item result', () {
      final outcomes = PractitionerScheduleSaver.mapBulkResults(
        [payload('sb-1'), payload('sb-2')],
        BulkUpsertAvailableDtResponse(data: [
          BulkUpsertResult(serviceBranchId: 'sb-1', success: true),
        ]),
      );
      expect(outcomes[1].success, isFalse);
      expect(outcomes[1].message, 'No result returned for this service.');
    });

    test('fails closed when the response has no data at all', () {
      final outcomes = PractitionerScheduleSaver.mapBulkResults(
        [payload('sb-1')],
        BulkUpsertAvailableDtResponse(code: 200),
      );
      expect(outcomes.single.success, isFalse);
    });
  });
}
