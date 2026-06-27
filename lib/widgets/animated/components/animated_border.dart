import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBorder extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final Duration duration;
  final bool autoPlay;
  final bool repeat;

  const AnimatedBorder({
    super.key,
    required this.child,
    this.gradientColors = const [
      Color(0xFF6C63FF),
      Color(0xFF00D4FF),
      Color(0xFFFF6B9D),
      Color(0xFF43E97B),
      Color(0xFF6C63FF),
    ],
    this.borderWidth = 2.0,
    this.borderRadius,
    this.duration = const Duration(seconds: 2),
    this.autoPlay = true,
    this.repeat = true,
  });

  @override
  State<AnimatedBorder> createState() => _AnimatedBorderState();
}

class _AnimatedBorderState extends State<AnimatedBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.autoPlay) {
      widget.repeat ? _controller.repeat() : _controller.forward();
    }
  }

  void play() => widget.repeat ? _controller.repeat() : _controller.forward();
  void stop() => _controller.stop();
  void reset() => _controller.reset();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _AnimatedBorderPainter(
          colors: widget.gradientColors,
          progress: _controller.value,
          borderWidth: widget.borderWidth,
          borderRadius: radius,
        ),
        child: Padding(
          padding: EdgeInsets.all(widget.borderWidth),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class _AnimatedBorderPainter extends CustomPainter {
  final List<Color> colors;
  final double progress;
  final double borderWidth;
  final BorderRadius borderRadius;

  _AnimatedBorderPainter({
    required this.colors,
    required this.progress,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    final paint = Paint()
      ..shader = SweepGradient(
        colors: colors,
        startAngle: 0,
        endAngle: pi * 2,
        transform: GradientRotation(progress * pi * 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_AnimatedBorderPainter old) => old.progress != progress;
}
