import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class NoiseBackground extends StatefulWidget {
  final Color? grainColor;
  final double opacity;
  final int fps;
  final double grainSize;
  final Widget? child;

  const NoiseBackground({
    super.key,
    this.grainColor,
    this.opacity = 0.06,
    this.fps = 12,
    this.grainSize = 1.0,
    this.child,
  });

  @override
  State<NoiseBackground> createState() => _NoiseBackgroundState();
}

class _NoiseBackgroundState extends State<NoiseBackground> {
  late Ticker _ticker;
  Duration _lastUpdate = Duration.zero;
  int _seed = 0;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final frameMs = 1000 ~/ widget.fps;
    if (elapsed - _lastUpdate >= Duration(milliseconds: frameMs)) {
      _lastUpdate = elapsed;
      if (mounted) setState(() => _seed = _random.nextInt(0x7FFFFFFF));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grainColor = widget.grainColor ??
        (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black);

    return Stack(
      children: [
        if (widget.child != null) Positioned.fill(child: widget.child!),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _NoisePainter(
                color: grainColor,
                opacity: widget.opacity,
                seed: _seed,
                grainSize: widget.grainSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoisePainter extends CustomPainter {
  final Color color;
  final double opacity;
  final int seed;
  final double grainSize;

  _NoisePainter({
    required this.color,
    required this.opacity,
    required this.seed,
    required this.grainSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;
    final gs = grainSize.clamp(0.5, 4.0);
    final count = ((size.width * size.height) / (gs * gs) * 0.25).toInt().clamp(0, 40000);

    for (int i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final alpha = random.nextDouble() * opacity;
      paint.color = color.withValues(alpha: alpha);
      canvas.drawRect(Rect.fromLTWH(x, y, gs, gs), paint);
    }
  }

  @override
  bool shouldRepaint(_NoisePainter old) => old.seed != seed;
}
