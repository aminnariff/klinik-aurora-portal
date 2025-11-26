import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';

bool notNullOrEmptyString(String? value) {
  if (value == null || value == '' || value == 'null') {
    return false;
  }
  return true;
}

int opacityCalculation(double value) {
  return (value * 255).toInt();
}

String statusTranslate(int? value) {
  if (value == 1) {
    return 'ACTIVE';
  } else {
    return 'INACTIVE';
  }
}

String? dateConverter(String? value, {String? format}) {
  try {
    if (value == null) {
      return null;
    } else {
      DateTime dateTime = DateTime.parse(value);
      dateTime = dateTime.add(const Duration(hours: 8));

      return DateFormat(format ?? 'dd-MM-yyyy HH:mm:ss').format(dateTime);
    }
  } catch (e) {
    return null;
  }
}

String doctorType(int? type) {
  switch (type) {
    case 1:
      return 'Doctor';

    case 2:
      return 'Sonographer';

    case 3:
      return 'Therapist';

    case 4:
      return 'Spa Therapist';

    default:
      return 'Doctor';
  }
}

String pointType(int? type) {
  switch (type) {
    case 1:
      return 'Referral';

    case 2:
      return 'Voucher';

    case 3:
      return 'Claim Reward';

    case 4:
      return 'Spending';

    case 5:
      return 'Expired';

    default:
      return 'Spending';
  }
}

String convertStringToDate(String dateString) {
  // Assuming the date is in day-month-year format
  List<String> parts = dateString.split('-');
  String formattedString = '${parts[2]}-${parts[1]}-${parts[0]}';

  return DateFormat('yyyy-MM-dd').format(DateTime.parse(formattedString));
}

String convertToMonthYear(int month, int year) {
  List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (month < 1 || month > 12) {
    throw ArgumentError('Month must be between 1 and 12');
  }
  String monthName = months[month - 1];
  return '$monthName $year';
}

String convertToDayMonth(String dateTimeString) {
  try {
    DateTime dateTime = DateTime.parse(dateTimeString);
    String formattedDate = DateFormat('dd-MM').format(dateTime);
    return formattedDate;
  } catch (e) {
    return dateTimeString;
  }
}

bool checkEndDate(String? endDate) {
  if (endDate == null) {
    return false;
  } else {
    try {
      return DateTime.parse(endDate).isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }
}

String convert24HourToAmPmFormat(String time) {
  final format = RegExp(r'^(\d{2}):(\d{2}):(\d{2})$');
  final match = format.firstMatch(time);

  if (match != null) {
    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);

    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  } else {
    throw FormatException('Invalid 24-hour format: $time');
  }
}

int calculateCustomerPoints(String amount) {
  double paidAmount = double.tryParse(amount) ?? 0.0;
  int points = (paidAmount / 10).floor();

  if (paidAmount < 10 && paidAmount > 0) {
    return 1;
  }

  return points;
}

String convertMalaysiaTimeToUtc(String malaysiaTimeStr, {bool plainFormat = false}) {
  try {
    final inputFormat = DateFormat('dd-MM-yyyy HH:mm');
    final malaysiaTime = inputFormat.parseStrict(malaysiaTimeStr);

    final utcTime = malaysiaTime.toUtc();

    if (plainFormat) {
      return "${utcTime.year.toString().padLeft(4, '0')}-"
          "${utcTime.month.toString().padLeft(2, '0')}-"
          "${utcTime.day.toString().padLeft(2, '0')} "
          "${utcTime.hour.toString().padLeft(2, '0')}:"
          "${utcTime.minute.toString().padLeft(2, '0')}:"
          "${utcTime.second.toString().padLeft(2, '0')}";
    }

    return utcTime.toIso8601String();
  } catch (e) {
    debugPrint('Error: $e');
    return '';
  }
}

String? convertUtcToMalaysiaTime(String? utcString, {bool showTime = true}) {
  try {
    if (utcString == null || utcString.isEmpty) return null;

    final utcDateTime = DateTime.parse(utcString);
    return formatAppointmentDate(utcDateTime, showTime);
  } catch (e) {
    debugPrint('Invalid date format: $e');
    return null;
  }
}

String formatAppointmentDate(DateTime dateTime, bool time) {
  final malaysiaDateTime = dateTime.add(const Duration(hours: 8)); // force +8
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final appointmentDay = DateTime(malaysiaDateTime.year, malaysiaDateTime.month, malaysiaDateTime.day);

  String dayLabel;
  if (appointmentDay == today) {
    dayLabel = 'Today';
  } else if (appointmentDay == tomorrow) {
    dayLabel = 'Tomorrow';
  } else {
    dayLabel = DateFormat('EEE, d MMM yyyy').format(malaysiaDateTime);
  }

  String timeLabel = DateFormat('h:mm a').format(malaysiaDateTime);

  return time ? '$dayLabel\n$timeLabel' : dayLabel;
}

String getAppointmentStatusLabel(int? statusId) {
  if (statusId == null) return 'Unknown';

  final match = appointmentStatus.firstWhere(
    (item) => item.key == statusId.toString(),
    orElse: () => DropdownAttribute('', 'Unknown'),
  );
  return match.name;
}

String formatToDisplayDate(String input) {
  final inputFormat = DateFormat("dd-MM-yyyy HH:mm");
  final dateTime = inputFormat.parse(input);
  return "${dateTime.day.toString().padLeft(2, '0')}-"
      "${dateTime.month.toString().padLeft(2, '0')}-"
      "${dateTime.year}";
}

String formatToDisplayTime(String input) {
  final inputFormat = DateFormat("dd-MM-yyyy HH:mm");
  final dateTime = inputFormat.parse(input);
  final formatter = DateFormat('h.mm a');
  return formatter.format(dateTime);
}

String? extractDobFromNric(String nric) {
  if (nric.length != 12) return null;

  final yearPart = nric.substring(0, 2);
  final monthPart = nric.substring(2, 4);
  final dayPart = nric.substring(4, 6);

  final now = DateTime.now();
  final currentYear = now.year % 100;
  final fullYear = int.parse(yearPart) > currentYear ? 1900 + int.parse(yearPart) : 2000 + int.parse(yearPart);

  try {
    final date = DateTime(fullYear, int.parse(monthPart), int.parse(dayPart));
    return DateFormat('dd-MM-yyyy').format(date);
  } catch (e) {
    return null;
  }
}
