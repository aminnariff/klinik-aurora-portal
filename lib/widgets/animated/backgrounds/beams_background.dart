import 'dart:math';
import 'package:flutter/material.dart';

class BeamsBackground extends StatefulWidget {
  final List<Color>? beamColors;
  final int beamCount;
  final Duration duration;
  final double beamWidth;
  final double beamAngle;
  final Widget? child;

  const BeamsBackground({
    super.key,
    this.beamColors,
    this.beamCount = 4,
    this.duration = const Duration(seconds: 5),
    this.beamWidth = 140.0,
    this.beamAngle = 0.45,
    this.child,
  });

  @override
  State<BeamsBackground> createState() => _BeamsBackgroundState();
}

class _BeamsBackgroundState extends State<BeamsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const _defaultColors = [
    Color(0x1A6C63FF),
    Color(0x1A00D4FF),
    Color(0x1AFF6B9D),
    Color(0x1A43E97B),
    Color(0x1AFFB347),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _BeamsPainter(
              colors: widget.beamColors ?? _defaultColors,
              count: widget.beamCount,
              progress: _controller.value,
              beamWidth: widget.beamWidth,
              angle: widget.beamAngle,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _BeamsPainter extends CustomPainter {
  final List<Color> colors;
  final int count;
  final double progress;
  final double beamWidth;
  final double angle;

  _BeamsPainter({
    required this.colors,
    required this.count,
    required this.progress,
    required this.beamWidth,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tanAngle = tan(angle);
    final sweep = size.width + size.height * tanAngle + beamWidth;

    for (int i = 0; i < count; i++) {
      final color = colors[i % colors.length];
      final offset = ((i / count + progress) % 1.0) * sweep - beamWidth;

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color,
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
          Rect.fromLTWH(offset, 0, beamWidth, size.height),
        );

      final path = Path();
      path.moveTo(offset, 0);
      path.lineTo(offset + beamWidth, 0);
      path.lineTo(offset + beamWidth + size.height * tanAngle, size.height);
      path.lineTo(offset + size.height * tanAngle, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BeamsPainter old) => old.progress != progress;
}
