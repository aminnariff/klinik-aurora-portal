import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class _Particle {
  Offset position;
  Offset velocity;
  final double radius;
  final double opacity;

  _Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.opacity,
  });
}

class ParticlesBackground extends StatefulWidget {
  final int count;
  final Color color;
  final double minRadius;
  final double maxRadius;
  final double speed;
  final bool connectLines;
  final double connectionDistance;
  final Widget? child;

  const ParticlesBackground({
    super.key,
    this.count = 50,
    this.color = const Color(0xFF6C63FF),
    this.minRadius = 1.0,
    this.maxRadius = 3.0,
    this.speed = 0.5,
    this.connectLines = false,
    this.connectionDistance = 100.0,
    this.child,
  });

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Particle> _particles = [];
  final _random = Random();
  Size _size = Size.zero;
  Duration _lastTime = Duration.zero;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _initParticles(Size size) {
    _particles.clear();
    for (int i = 0; i < widget.count; i++) {
      _particles.add(_Particle(
        position: Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
        ),
        velocity: Offset(
          (_random.nextDouble() - 0.5) * widget.speed * 2,
          (_random.nextDouble() - 0.5) * widget.speed * 2,
        ),
        radius:
            widget.minRadius + _random.nextDouble() * (widget.maxRadius - widget.minRadius),
        opacity: 0.3 + _random.nextDouble() * 0.7,
      ));
    }
    _initialized = true;
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final dt = (elapsed - _lastTime).inMilliseconds.clamp(0, 50).toDouble();
    _lastTime = elapsed;
    if (!_initialized) return;

    for (final p in _particles) {
      p.position += p.velocity * dt;
      if (p.position.dx < 0 || p.position.dx > _size.width) {
        p.velocity = Offset(-p.velocity.dx, p.velocity.dy);
        p.position = Offset(p.position.dx.clamp(0, _size.width), p.position.dy);
      }
      if (p.position.dy < 0 || p.position.dy > _size.height) {
        p.velocity = Offset(p.velocity.dx, -p.velocity.dy);
        p.position = Offset(p.position.dx, p.position.dy.clamp(0, _size.height));
      }
    }
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
        if (newSize != _size && newSize.width > 0 && newSize.height > 0) {
          _size = newSize;
          _initParticles(_size);
        }
        return Stack(
          children: [
            if (_initialized)
              CustomPaint(
                size: _size,
                painter: _ParticlesPainter(
                  particles: _particles,
                  color: widget.color,
                  connectLines: widget.connectLines,
                  connectionDistance: widget.connectionDistance,
                ),
              ),
            if (widget.child != null) Positioned.fill(child: widget.child!),
          ],
        );
      },
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final bool connectLines;
  final double connectionDistance;

  _ParticlesPainter({
    required this.particles,
    required this.color,
    required this.connectLines,
    required this.connectionDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..strokeWidth = 0.5;

    if (connectLines) {
      for (int i = 0; i < particles.length; i++) {
        for (int j = i + 1; j < particles.length; j++) {
          final dist = (particles[i].position - particles[j].position).distance;
          if (dist < connectionDistance) {
            final alpha = (1 - dist / connectionDistance) * 0.4;
            linePaint.color = color.withValues(alpha: alpha);
            canvas.drawLine(particles[i].position, particles[j].position, linePaint);
          }
        }
      }
    }

    for (final p in particles) {
      dotPaint.color = color.withValues(alpha: p.opacity);
      canvas.drawCircle(p.position, p.radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => true;
}
