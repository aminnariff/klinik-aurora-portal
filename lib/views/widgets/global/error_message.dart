import 'package:easy_localization/easy_localization.dart';

abstract class ErrorMessage {
  static String minLength(String fieldName, int minLength) {
    return "$fieldName ${'error-message'.tr(gender: 'mustBeAtLeast')} $minLength ${'error-message'.tr(gender: 'charactersLong')}";
  }

  static String maxLength(String fieldName, int maxLength) {
    return "The maximum allowed characters are $maxLength";
  }

  static String required({String? field}) =>
      '${field ?? 'error-message'.tr(gender: 'thisField')} ${'error-message'.tr(gender: 'isRequired')}';
}
