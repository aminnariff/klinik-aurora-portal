import 'package:flutter/material.dart';

class DarkModeController extends ChangeNotifier {
  bool _darkMode = false;
  bool get darkMode => _darkMode;

  set darkMode(bool value) {
    _darkMode = value;
    notifyListeners();
  }
}
