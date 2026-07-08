import 'package:flutter/material.dart';

/// Bridges [AuthController.sessionExpiredByInactivity] to the widget tree.
///
/// The [Homepage] listens to [status] and redirects to the login page when
/// it becomes `true`.  The actual inactivity detection runs inside
/// [AuthController]'s periodic timer.
class ActivityHandlerController extends ChangeNotifier {
  bool _status = false;
  bool get status => _status;

  /// Called by [Homepage] when it detects [AuthController.sessionExpiredByInactivity].
  void markInactive() {
    if (!_status) {
      _status = true;
      notifyListeners();
    }
  }

  /// Called after logout / redirect completes.
  void reset() {
    _status = false;
    notifyListeners();
  }
}
