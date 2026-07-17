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
        // Pin the exact record the wizard resolved and previewed, so the
        // backend updates the same row the merge was computed from.
        if (existingRecordId != null) 'serviceBranchAvailableDatetimeId': existingRecordId,
        'availableDatetimes': availableDatetimes,
      };
}
