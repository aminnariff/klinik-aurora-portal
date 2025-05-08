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
      dateTime = dateTime.toUtc().add(const Duration(hours: 8));

      return DateFormat(format ?? 'dd-MM-yyyy HH:mm:ss').format(dateTime);
    }
  } catch (e) {
    return null;
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

String? convertUtcToMalaysiaTime(String? utcString, {bool showTime = true}) {
  try {
    if (utcString == null || utcString.isEmpty) return null;
    final utcDateTime = DateTime.parse(utcString).toUtc();

    return formatAppointmentDate(utcDateTime, showTime);
  } catch (e) {
    debugPrint('Invalid date format: $e');
    return null;
  }
}

String formatAppointmentDate(DateTime dateTime, bool time) {
  final now = DateTime.now();
  final malaysiaDateTime = dateTime.toLocal().subtract(const Duration(hours: 8));
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final appointmentDay = DateTime(malaysiaDateTime.year, malaysiaDateTime.month, malaysiaDateTime.day);

  String dayLabel;
  if (appointmentDay == today) {
    dayLabel = 'Today';
  } else if (appointmentDay == tomorrow) {
    dayLabel = 'Tomorrow';
  } else {
    dayLabel = DateFormat('EEE, d MMM yyyy').format(malaysiaDateTime); // e.g. Mon, 6 May 2025
  }

  String timeLabel = DateFormat('h:mm a').format(malaysiaDateTime);
  if (time == false) {
    return dayLabel;
  }
  return '$dayLabel\n$timeLabel';
}

String getAppointmentStatusLabel(int? statusId) {
  if (statusId == null) return 'Unknown';

  final match = appointmentStatus.firstWhere(
    (item) => item.key == statusId.toString(),
    orElse: () => DropdownAttribute('', 'Unknown'),
  );
  return match.name;
}
