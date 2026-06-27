import 'dart:math';
import 'package:flutter/material.dart';

class SuccessCheckmark extends StatefulWidget {
  final Color? color;
  final Color? circleColor;
  final double size;
  final Duration duration;
  final bool autoPlay;
  final VoidCallback? onComplete;
  final bool showCircle;

  const SuccessCheckmark({
    super.key,
    this.color,
    this.circleColor,
    this.size = 64.0,
    this.duration = const Duration(milliseconds: 800),
    this.autoPlay = true,
    this.onComplete,
    this.showCircle = true,
  });

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnim;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _circleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _checkAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    if (widget.autoPlay) {
      _controller.forward().then((_) => widget.onComplete?.call());
    }
  }

  void play() {
    _controller.reset();
    _controller.forward().then((_) => widget.onComplete?.call());
  }

  void reset() => _controller.reset();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final circleColor = widget.circleColor ?? checkColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _CheckmarkPainter(
          checkProgress: _checkAnim.value,
          circleProgress: _circleAnim.value,
          checkColor: checkColor,
          circleColor: circleColor,
          showCircle: widget.showCircle,
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double checkProgress;
  final double circleProgress;
  final Color checkColor;
  final Color circleColor;
  final bool showCircle;

  _CheckmarkPainter({
    required this.checkProgress,
    required this.circleProgress,
    required this.checkColor,
    required this.circleColor,
    required this.showCircle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide / 2;

    if (showCircle) {
      final circlePaint = Paint()
        ..color = circleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.06
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.9),
        -pi / 2,
        2 * pi * circleProgress,
        false,
        circlePaint,
      );
    }

    if (checkProgress <= 0) return;

    // Checkmark: two segments — down-right, then up-right
    final p1 = Offset(cx - r * 0.32, cy);
    final p2 = Offset(cx - r * 0.05, cy + r * 0.28);
    final p3 = Offset(cx + r * 0.38, cy - r * 0.28);

    final totalLength = (p2 - p1).distance + (p3 - p2).distance;
    final drawn = totalLength * checkProgress;

    final checkPaint = Paint()
      ..color = checkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final seg1Len = (p2 - p1).distance;

    if (drawn <= seg1Len) {
      final t = drawn / seg1Len;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      final remaining = drawn - seg1Len;
      final seg2Len = (p3 - p2).distance;
      final t = (remaining / seg2Len).clamp(0.0, 1.0);
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }

    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) =>
      old.checkProgress != checkProgress || old.circleProgress != circleProgress;
}
