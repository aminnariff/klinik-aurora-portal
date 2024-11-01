import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Allow only numbers and one decimal point
    final newText = newValue.text;

    // Check if the input has more than one decimal point
    if (newText.contains('.') && newText.split('.').length > 2) {
      return oldValue;
    }

    // Restrict to two decimal places
    if (newText.contains('.') && newText.split('.').last.length > 2) {
      return oldValue;
    }

    return newValue;
  }
}
