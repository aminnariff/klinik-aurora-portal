import 'package:flutter/services.dart';

class UpperCaseAlphaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text.split('').map((char) {
      if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
        return char.toUpperCase();
      }
      return char;
    }).join();

    return newValue.copyWith(text: newText, selection: newValue.selection);
  }
}
