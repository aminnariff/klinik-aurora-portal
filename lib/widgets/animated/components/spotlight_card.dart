import 'package:flutter/material.dart';

class SpotlightCard extends StatefulWidget {
  final Widget child;
  final double spotlightRadius;
  final Color spotlightColor;
  final double spotlightOpacity;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const SpotlightCard({
    super.key,
    required this.child,
    this.spotlightRadius = 200.0,
    this.spotlightColor = Colors.white,
    this.spotlightOpacity = 0.12,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.padding,
    this.width,
    this.height,
  });

  @override
  State<SpotlightCard> createState() => _SpotlightCardState();
}

class _SpotlightCardState extends State<SpotlightCard> {
  Offset? _pointerPosition;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final bgColor = widget.backgroundColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF8F8FF));

    return ClipRRect(
      borderRadius: radius,
      child: MouseRegion(
        onHover: (event) => setState(() => _pointerPosition = event.localPosition),
        onExit: (_) => setState(() => _pointerPosition = null),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
            border: widget.border ??
                Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
          ),
          child: Stack(
            children: [
              widget.child,
              if (_pointerPosition != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SpotlightPainter(
                        center: _pointerPosition!,
                        radius: widget.spotlightRadius,
                        color: widget.spotlightColor
                            .withValues(alpha: widget.spotlightOpacity),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  _SpotlightPainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.center != center;
}
