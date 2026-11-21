import 'package:flutter/material.dart';

import '../../widgets/motion/emil_motion.dart';

/// A one-shot entrance for a dashboard panel within the current clinic scope.
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({super.key, required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = EmilMotion.staggerStep.inMilliseconds * order.clamp(0, 3);
    final duration = EmilMotion.shellFadeDuration.inMilliseconds + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: duration),
      curve: Interval(delay / duration, 1, curve: EmilMotion.easeOut),
      child: RepaintBoundary(child: child),
      builder: (_, progress, child) => Opacity(
        opacity: .55 + .45 * progress,
        child: Transform.translate(offset: Offset(0, (1 - progress) * 6), transformHitTests: false, child: child),
      ),
    );
  }
}
