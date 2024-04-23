import 'dart:async';
import 'dart:html' as html;

import 'package:shared_preferences/shared_preferences.dart';

class UserActivityHandler {
  Timer? _inactivityTimer;
  final Duration timeout;
  final void Function() onTimeout;

  UserActivityHandler({required this.timeout, required this.onTimeout});

  Future<void> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      _startListening();
    }
  }

  void _startListening() {
    html.window.onMouseDown.listen((_) => _resetTimer());
    html.window.onKeyDown.listen((_) => _resetTimer());
    html.window.onMouseMove.listen((_) => _resetTimer());
    html.window.onTouchStart.listen((_) => _resetTimer());
    _resetTimer();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(timeout, onTimeout);
  }

  void dispose() {
    _inactivityTimer?.cancel();
  }
}
