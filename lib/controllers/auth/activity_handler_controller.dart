import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/auth/user_activity_controller.dart';

class ActivityHandlerController with ChangeNotifier {
  late UserActivityHandler _handler;
  bool _status = false;
  bool get status => _status;

  ActivityHandlerController() {
    _status = false;
    _handler = UserActivityHandler(
      timeout: const Duration(minutes: 30),
      onTimeout: handleTimeout,
    );
    _handler.initialize();
  }

  void handleTimeout() {
    _status = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _handler.dispose();
    super.dispose();
  }
}
