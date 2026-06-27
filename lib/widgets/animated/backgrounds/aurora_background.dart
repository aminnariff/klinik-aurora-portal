import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class _AuroraBlob {
  final Offset baseCenter;
  final double radius;
  final Color color;
  final double phase;
  final double phaseSpeed;
  final double amplitude;

  const _AuroraBlob({
    required this.baseCenter,
    required this.radius,
    required this.color,
    required this.phase,
    required this.phaseSpeed,
    required this.amplitude,
  });
}

class AuroraBackground extends StatefulWidget {
  final List<Color>? colors;
  final int blobCount;
  final Duration cycleDuration;
  final Widget? child;

  const AuroraBackground({
    super.key,
    this.colors,
    this.blobCount = 4,
    this.cycleDuration = const Duration(seconds: 12),
    this.child,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_AuroraBlob> _blobs = [];
  final _random = Random();
  double _time = 0;
  Size _size = Size.zero;

  static const _defaultColors = [
    Color(0x806C63FF),
    Color(0x8000D4FF),
    Color(0x80FF6B9D),
    Color(0x8043E97B),
    Color(0x80FFB347),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _initBlobs(Size size) {
    _blobs.clear();
    final colors = widget.colors ?? _defaultColors;
    for (int i = 0; i < widget.blobCount; i++) {
      _blobs.add(_AuroraBlob(
        baseCenter: Offset(
          size.width * (0.1 + _random.nextDouble() * 0.8),
          size.height * (0.1 + _random.nextDouble() * 0.8),
        ),
        radius: size.shortestSide * (0.25 + _random.nextDouble() * 0.35),
        color: colors[i % colors.length],
        phase: _random.nextDouble() * pi * 2,
        phaseSpeed: 0.2 + _random.nextDouble() * 0.6,
        amplitude: size.shortestSide * (0.06 + _random.nextDouble() * 0.08),
      ));
    }
  }

  void _onTick(Duration elapsed) {
    _time = elapsed.inMilliseconds / widget.cycleDuration.inMilliseconds * pi * 2;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final newSize = Size(constraints.maxWidth, constraints.maxHeight);
        if ((newSize != _size) && newSize.width > 0) {
          _size = newSize;
          _initBlobs(_size);
        }
        return Stack(
          children: [
            CustomPaint(
              size: _size,
              painter: _AuroraPainter(blobs: _blobs, time: _time),
            ),
            if (widget.child != null) Positioned.fill(child: widget.child!),
          ],
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final List<_AuroraBlob> blobs;
  final double time;

  _AuroraPainter({required this.blobs, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final blob in blobs) {
      final dx = sin(time * blob.phaseSpeed + blob.phase) * blob.amplitude;
      final dy = cos(time * blob.phaseSpeed * 0.7 + blob.phase + 1) * blob.amplitude;
      final center = blob.baseCenter + Offset(dx, dy);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [blob.color, blob.color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: blob.radius));

      canvas.drawCircle(center, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.time != time;
}
