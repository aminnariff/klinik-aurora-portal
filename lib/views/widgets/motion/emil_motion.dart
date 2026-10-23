import 'package:flutter/material.dart';

/// Emil Kowalski's animation curves and durations tailored for Flutter UI.
///
/// Principles:
/// 1. UI transitions should stay under 300ms.
/// 2. Use strong custom ease-out curves instead of weak standard curves.
/// 3. Never animate entry from scale(0); start from scale(0.95) with opacity.
/// 4. Buttons must feel responsive: scale(0.97) on active press.
abstract class EmilMotion {
  /// Strong ease-out: starts fast, feels instant.
  /// Matches CSS cubic-bezier(0.23, 1, 0.32, 1).
  static const Curve easeOut = Cubic(0.23, 1.0, 0.32, 1.0);

  /// Strong ease-in-out: for natural acceleration & deceleration of on-screen elements.
  /// Matches CSS cubic-bezier(0.77, 0, 0.175, 1).
  static const Curve easeInOut = Cubic(0.77, 0.0, 0.175, 1.0);

  /// Active button press duration (140ms).
  static const Duration pressDuration = Duration(milliseconds: 140);

  /// Button press release duration (120ms).
  static const Duration releaseDuration = Duration(milliseconds: 120);

  /// Dialog and modal entrance duration (200ms).
  static const Duration modalDuration = Duration(milliseconds: 200);

  /// Toast slide-in/fade duration (220ms).
  static const Duration toastDuration = Duration(milliseconds: 220);
}

/// Wraps any button or interactive element to provide Emil's scale(0.97) active press feedback.
class EmilPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const EmilPressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<EmilPressable> createState() => _EmilPressableState();
}

class _EmilPressableState extends State<EmilPressable> {
  bool _isPressed = false;

  void _setPressed(bool val) {
    if (!widget.enabled || widget.onTap == null) return;
    if (_isPressed != val) {
      setState(() => _isPressed = val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: _isPressed ? EmilMotion.pressDuration : EmilMotion.releaseDuration,
        curve: EmilMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Dialog card entrance animation: scales smoothly from 0.95 to 1.0 with fade.
/// Never animates from scale(0) to avoid jarring pop-in.
class EmilModalTransition extends StatelessWidget {
  final Widget child;

  const EmilModalTransition({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: EmilMotion.modalDuration,
      curve: EmilMotion.easeOut,
      builder: (context, progress, c) {
        return Opacity(
          opacity: progress,
          child: Transform.scale(
            scale: 0.95 + (0.05 * progress),
            alignment: Alignment.center,
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}
