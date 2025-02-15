import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

bool notNullOrEmptyString(String? value) {
  if (value == null || value == '' || value == 'null') {
    return false;
  }
  return true;
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

int calculateCustomerPoints(String amount) {
  double paidAmount = double.tryParse(amount) ?? 0.0;
  int points = (paidAmount / 10).floor();

  if (paidAmount < 10 && paidAmount > 0) {
    return 1;
  }

  return points;
}
