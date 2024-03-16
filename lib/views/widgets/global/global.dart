import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

bool notNullOrEmptyString(String? value) {
  if (value == null || value == '' || value == 'null') {
    return false;
  }
  return true;
}

String? dateConverter(String? value) {
  try {
    if (value == null) {
      return null;
    } else {
      DateTime dateTime = DateTime.parse(value);
      dateTime = dateTime.toUtc().add(const Duration(hours: 8));

      return DateFormat('dd-MM-yyyy HH:mm:ss').format(dateTime);
    }
  } catch (e) {
    return null;
  }
}
