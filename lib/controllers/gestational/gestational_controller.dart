import 'package:intl/intl.dart';

enum GestationalEligibility {
  notYetEligible,
  notYetEligibleGrace, // within X day(s) before
  eligible,
  exceededGrace, // within X day(s) after
  tooFar,
}

final int bufferDays = 0;

class GestationalController {
  final GestationalEligibility status;
  final String gestationalAge;

  GestationalController({required this.status, required this.gestationalAge});
}

GestationalController getGestationalStatusFromString({
  required String eddStr,
  required String range,
  required DateTime appointmentDate,
}) {
  final edd = DateFormat('dd-MM-yyyy').parseStrict(eddStr);
  final lmp = edd.subtract(const Duration(days: 280)); // 40 weeks standard
  final daysPregnant = appointmentDate.difference(lmp).inDays;
  final weeks = daysPregnant ~/ 7;
  final days = daysPregnant % 7;

  final gestationalAgeString = '$weeks weeks, $days days';

  final parts = range.split('-');
  final start = _parseGestationalRange(parts[0]);
  final end = _parseGestationalRange(parts[1]);

  final currentDays = weeks * 7 + days;

  if (currentDays < start - bufferDays) {
    return GestationalController(status: GestationalEligibility.notYetEligible, gestationalAge: gestationalAgeString);
  } else if (currentDays >= start - bufferDays && currentDays < start) {
    return GestationalController(
      status: GestationalEligibility.notYetEligibleGrace,
      gestationalAge: gestationalAgeString,
    );
  } else if (currentDays >= start && currentDays <= end) {
    return GestationalController(status: GestationalEligibility.eligible, gestationalAge: gestationalAgeString);
  } else if (currentDays > end && currentDays <= end + bufferDays) {
    return GestationalController(status: GestationalEligibility.exceededGrace, gestationalAge: gestationalAgeString);
  } else {
    return GestationalController(status: GestationalEligibility.tooFar, gestationalAge: gestationalAgeString);
  }
}

int _parseGestationalRange(String input) {
  final regex = RegExp(r'(\d+)w(\d+)d');
  final match = regex.firstMatch(input);
  if (match != null) {
    final weeks = int.parse(match.group(1)!);
    final days = int.parse(match.group(2)!);
    return weeks * 7 + days;
  }
  return 0;
}

String? getPromptMessage({
  required GestationalEligibility status,
  required String gestationalAge,
  required String serviceName,
}) {
  switch (status) {
    case GestationalEligibility.notYetEligibleGrace:
      return 'You are currently $gestationalAge pregnant, which is within $bufferDays day(s) *before* the eligible window to perform "$serviceName". '
          'This may affect the scan accuracy. Are you sure you want to proceed?';

    case GestationalEligibility.exceededGrace:
      return 'You are currently $gestationalAge pregnant, which is within $bufferDays day(s) *after* the eligible window to perform "$serviceName". '
          'This may affect the scan accuracy. Are you sure you want to proceed?';

    default:
      return null;
  }
}

String? getGestationalStatusMessage({GestationalController? result, required String range, bool showRange = false}) {
  if (result != null) {
    final age = result.gestationalAge;
    final rangeText = showRange ? " (Allowed range: $range)" : "";

    switch (result.status) {
      case GestationalEligibility.eligible:
        return "The patient is eligible. Estimated gestational age at appointment: $age$rangeText.";

      case GestationalEligibility.notYetEligible:
        return "The patient is not yet eligible. She will be $age at the time of the appointment$rangeText.";

      case GestationalEligibility.notYetEligibleGrace:
        return "The patient is slightly early (gestational age: $age).";

      case GestationalEligibility.exceededGrace:
        return "The patient is slightly past the ideal window (gestational age: $age).";

      case GestationalEligibility.tooFar:
        return "The patient is no longer eligible. She will be $age at the time of the appointment$rangeText.";
    }
  }
  return null;
}

String? calculateGestationalAge({required String edd, required String appointmentDate}) {
  try {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final eddDate = dateFormat.parse(edd);
    final appointment = dateFormat.parse(appointmentDate);

    final conceptionDate = eddDate.subtract(const Duration(days: 280));
    final difference = appointment.difference(conceptionDate);
    final weeks = difference.inDays ~/ 7;
    final days = difference.inDays % 7;

    return '$weeks week${weeks != 1 ? 's' : ''} $days day${days != 1 ? 's' : ''}';
  } catch (e) {
    return null;
  }
}

String translateGestationalRange(String input) {
  final parts = input.split('-');
  if (parts.length != 2) return '';

  String formatPart(String part) {
    final regex = RegExp(r'(\d+)w(\d+)d');
    final match = regex.firstMatch(part.trim());

    if (match != null) {
      final weeks = int.parse(match.group(1)!);
      final days = int.parse(match.group(2)!);
      return '$weeks week${weeks != 1 ? 's' : ''} $days day${days != 1 ? 's' : ''}';
    }
    return '';
  }

  final start = formatPart(parts[0]);
  final end = formatPart(parts[1]);

  return '$start to $end';
}
