import 'dart:async';

/// Monitors user activity by periodically checking [AuthController]'s
/// persisted last-activity timestamp.  No longer depends on `dart:html`.
///
/// Kept for backward compatibility — the new approach uses
/// [InactivityWatcher] widget + [AuthController]'s built-in periodic timer.
class UserActivityHandler {
  Timer? _checkTimer;
  final Duration timeout;
  final void Function() onTimeout;
  final bool Function() isAuthenticated;

  UserActivityHandler({required this.timeout, required this.onTimeout, required this.isAuthenticated});

  /// Start a periodic check that fires [onTimeout] when idle time exceeds [timeout].
  void start({Duration interval = const Duration(seconds: 30)}) {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(interval, (_) {
      if (!isAuthenticated()) return;
      onTimeout();
    });
  }

  void dispose() {
    _checkTimer?.cancel();
  }
}
