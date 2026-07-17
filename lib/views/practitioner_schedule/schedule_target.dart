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
