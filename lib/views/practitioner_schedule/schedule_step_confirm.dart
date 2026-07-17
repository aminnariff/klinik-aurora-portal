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

    // Memoize expandSchedule per distinct gap: many services share one gap.
    final countByGap = <int, int>{};
    int slotCount(int gapMinutes) =>
        countByGap[gapMinutes] ??= expandSchedule(schedule, gapMinutes).length;

    final bool anyFailed = outcomes != null && outcomes!.any((o) => !o.success);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryBanner(periodLabel, excludedCount, customCount),
          if (saving) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[600]),
                ),
                const SizedBox(width: 10),
                Text(
                  'Applying schedule — please keep this window open…',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          for (final target in targets) _row(context, target, slotCount),
          if (anyFailed) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: saving ? null : onRetryFailed,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFEA580C)),
              label: const Text(
                'Retry failed services',
                style: TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEA580C)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryBanner(String periodLabel, int excludedCount, int customCount) {
    final buffer = StringBuffer(
      '${targets.length} service${targets.length == 1 ? '' : 's'} will be updated. '
      'Existing slots inside this period will be replaced; slots outside it are kept.',
    );
    if (excludedCount > 0) {
      buffer.write(' $excludedCount date${excludedCount == 1 ? '' : 's'} excluded.');
    }
    if (customCount > 0) {
      buffer.write(' $customCount date${customCount == 1 ? '' : 's'} with custom hours.');
    }
    return Container(
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
          Text(
            '$doctorTypeLabel schedule · $periodLabel',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            buffer.toString(),
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF166534), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ScheduleTarget target, int Function(int) slotCount) {
    final outcome = outcomes?.cast<SaveOutcome?>().firstWhere(
          (o) => o!.payload.serviceBranchId == target.service.serviceBranchId,
          orElse: () => null,
        );
    final bool hasOutcome = outcome != null;
    final bool failed = hasOutcome && !outcome.success;
    final bool succeeded = hasOutcome && outcome.success;

    IconData statusIcon;
    Color statusColor;
    Color borderColor;
    if (succeeded) {
      statusIcon = Icons.check_circle_rounded;
      statusColor = const Color(0xFF16A34A);
      borderColor = const Color(0xFFBBF7D0);
    } else if (failed) {
      statusIcon = Icons.error_rounded;
      statusColor = const Color(0xFFDC2626);
      borderColor = const Color(0xFFFECACA);
    } else {
      statusIcon = Icons.radio_button_unchecked_rounded;
      statusColor = const Color(0xFFD1D5DB);
      borderColor = const Color(0xFFE5E7EB);
    }

    final count = slotCount(target.gapMinutes);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 20, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target.service.serviceName ?? '—',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (failed) ...[
                  const SizedBox(height: 2),
                  Text(
                    outcome.message ?? 'Failed to save.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${target.gapMinutes} min gap · $count slot${count == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 12,
              color: secondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
