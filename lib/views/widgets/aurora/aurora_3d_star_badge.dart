import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lightweight, 60fps rotating 3D metallic star badge.
/// Zero network bandwidth / asset download (pure vector GPU canvas).
class Aurora3DStarBadge extends StatefulWidget {
  final double size;
  const Aurora3DStarBadge({super.key, this.size = 38});

  @override
  State<Aurora3DStarBadge> createState() => _Aurora3DStarBadgeState();
}

class _Aurora3DStarBadgeState extends State<Aurora3DStarBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        final angle = progress * 2 * math.pi;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withAlpha(50),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(angle)
              ..rotateX(0.12),
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _Aurora3DStarPainter(progress: progress),
            ),
          ),
        );
      },
    );
  }
}

class _Aurora3DStarPainter extends CustomPainter {
  final double progress;
  _Aurora3DStarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.46;
    final innerR = outerR * 0.48;

    final path = Path();
    const points = 5;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final a = (i * math.pi / points) - math.pi / 2;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final sweepAngle = (progress * 2 * math.pi) % (2 * math.pi);
    final gradient = LinearGradient(
      begin: Alignment(math.cos(sweepAngle), math.sin(sweepAngle)),
      end: Alignment(-math.cos(sweepAngle), -math.sin(sweepAngle)),
      colors: const [
        Color(0xFFFFFBEB),
        Color(0xFFFDE68A),
        Color(0xFFF59E0B),
        Color(0xFFD97706),
        Color(0xFF92400E),
        Color(0xFFFFFBEB),
      ],
      stops: const [0.0, 0.2, 0.45, 0.7, 0.85, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white.withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: const [Colors.white, Color(0xFFFDE047), Color(0xFFD97706)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: innerR * 0.7));
    canvas.drawCircle(Offset(cx, cy), innerR * 0.5, corePaint);
  }

  @override
  bool shouldRepaint(covariant _Aurora3DStarPainter oldDelegate) => oldDelegate.progress != progress;
}
