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
    return mapBulkResults(payloads, response.data);
  }

  /// Pure mapping from the bulk response to per-service outcomes.
  /// Fail-closed: a payload with no matching per-item result is reported as
  /// failed — a false failure only triggers a harmless retry (the upsert is
  /// idempotent), while a false success would silently drop a schedule.
  @visibleForTesting
  static List<SaveOutcome> mapBulkResults(
    List<SchedulePayload> payloads,
    BulkUpsertAvailableDtResponse? response,
  ) {
    final results = <String?, BulkUpsertResult>{
      for (final r in response?.data ?? <BulkUpsertResult>[]) r.serviceBranchId: r,
    };
    return [
      for (final p in payloads)
        SaveOutcome(
          payload: p,
          success: results[p.serviceBranchId]?.success ?? false,
          message: results.containsKey(p.serviceBranchId)
              ? results[p.serviceBranchId]?.message
              : 'No result returned for this service.',
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
