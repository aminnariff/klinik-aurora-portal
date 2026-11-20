import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../glass/app_glass.dart';

/// Emil Kowalski's animation curves and durations tailored for Flutter UI.
///
/// Principles:
/// 1. UI transitions should stay under 300ms.
/// 2. Use strong custom ease-out curves instead of weak standard curves.
/// 3. Never animate entry from scale(0); start from scale(0.95) with opacity.
/// 4. Buttons must feel responsive: scale(0.97) on active press.
abstract class EmilMotion {
  static const pageDuration = Duration(milliseconds: 240);
  static const pageReverseDuration = Duration(milliseconds: 190);
  static const shellFadeDuration = Duration(milliseconds: 160);
  static const staggerStep = Duration(milliseconds: 35);
  static const Curve easeDrawer = Cubic(0.32, 0.72, 0.0, 1.0);

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

  const EmilPressable({super.key, required this.child, this.onTap, this.enabled = true});

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
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: (!reducedMotion && _isPressed) ? 0.97 : 1.0,
          duration: reducedMotion
              ? Duration.zero
              : (_isPressed ? EmilMotion.pressDuration : EmilMotion.releaseDuration),
          curve: EmilMotion.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Dialog card entrance animation: scales smoothly from 0.95 to 1.0 with fade.
/// Never animates from scale(0) to avoid jarring pop-in.
/// Honors [MediaQuery.disableAnimationsOf] for reduced-motion accessibility.
class EmilModalTransition extends StatelessWidget {
  final Widget child;

  const EmilModalTransition({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: EmilMotion.modalDuration,
      curve: EmilMotion.easeOut,
      builder: (context, progress, c) {
        return Opacity(
          opacity: progress,
          child: Transform.scale(scale: 0.95 + (0.05 * progress), alignment: Alignment.center, child: c),
        );
      },
      child: child,
    );
  }
}

enum AuroraTransitionType { drillIn, modalUp, shellFade }

abstract final class AuroraPageRoute {
  static Page<T> drillIn<T>(BuildContext context, {LocalKey? key, required Widget child}) =>
      _page(context, key, child, AuroraTransitionType.drillIn);

  static Page<T> modalUp<T>(BuildContext context, {LocalKey? key, required Widget child}) =>
      _page(context, key, child, AuroraTransitionType.modalUp);

  static Page<T> shellFade<T>(BuildContext context, {LocalKey? key, required Widget child}) =>
      _page(context, key, child, AuroraTransitionType.shellFade);

  static Page<T> _page<T>(BuildContext context, LocalKey? key, Widget child, AuroraTransitionType type) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return NoTransitionPage<T>(key: key, child: child);
    }
    final shell = type == AuroraTransitionType.shellFade;
    final offset = switch (type) {
      AuroraTransitionType.drillIn => const Offset(0.04, 0),
      AuroraTransitionType.modalUp => const Offset(0, 0.08),
      AuroraTransitionType.shellFade => const Offset(0, 0.015),
    };
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: shell ? EmilMotion.shellFadeDuration : EmilMotion.pageDuration,
      reverseTransitionDuration: shell ? EmilMotion.shellFadeDuration : EmilMotion.pageReverseDuration,
      transitionsBuilder: (context, animation, secondary, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final progress = animation.drive(CurveTween(curve: EmilMotion.easeOut));
        if (shell) {
          return FadeTransition(
            opacity: progress,
            child: AnimatedBuilder(
              animation: progress,
              child: child,
              builder: (_, child) => Transform.translate(offset: Offset(0, (1 - progress.value) * 6), child: child),
            ),
          );
        }
        return FadeTransition(
          opacity: progress,
          child: SlideTransition(
            position: progress.drive(Tween(begin: offset, end: Offset.zero)),
            textDirection: Directionality.maybeOf(context),
            child: child,
          ),
        );
      },
    );
  }
}

class AuroraStaggerItem extends StatelessWidget {
  const AuroraStaggerItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (index >= 6 || MediaQuery.disableAnimationsOf(context)) return child;
    final delay = EmilMotion.staggerStep.inMilliseconds * index.clamp(0, 5);
    const entrance = 105;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: delay + entrance),
      curve: Interval(delay / (delay + entrance), 1, curve: EmilMotion.easeOut),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
      ),
    );
  }
}

class AuroraCountUp extends StatelessWidget {
  const AuroraCountUp({super.key, required this.value, required this.builder});

  final num value;
  final Widget Function(BuildContext, num) builder;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 380),
      curve: EmilMotion.easeOut,
      builder: (context, value, _) => builder(context, value),
    );
  }
}

class AuroraSheetTransition extends StatelessWidget {
  const AuroraSheetTransition({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(20));
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Material(
          color: AppGlass.surfaceFill(context),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  label: MaterialLocalizations.of(context).closeButtonLabel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    onVerticalDragEnd: (details) {
                      if ((details.primaryVelocity ?? 0) > 100) Navigator.of(context).pop();
                    },
                    child: SizedBox(
                      width: 80,
                      height: 28,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.outline,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showAuroraModalSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  final navigator = Navigator.of(context);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: reduce ? Duration.zero : EmilMotion.pageDuration,
      reverseTransitionDuration: reduce ? Duration.zero : EmilMotion.pageReverseDuration,
      pageBuilder: (context, animation, _) => SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SizedBox(
                width: double.infinity,
                child: SlideTransition(
                  position: animation.drive(
                    Tween(
                      begin: reduce ? Offset.zero : const Offset(0, 1),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: EmilMotion.easeDrawer)),
                  ),
                  child: themes.wrap(AuroraSheetTransition(child: Builder(builder: builder))),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
