import 'package:flutter/material.dart';

enum GridStyle { dots, lines, crosshatch }

class GridBackground extends StatefulWidget {
  final GridStyle gridStyle;
  final double spacing;
  final Color? color;
  final double dotRadius;
  final bool animated;
  final Duration animationDuration;
  final Widget? child;

  const GridBackground({
    super.key,
    this.gridStyle = GridStyle.dots,
    this.spacing = 30.0,
    this.color,
    this.dotRadius = 1.5,
    this.animated = false,
    this.animationDuration = const Duration(seconds: 3),
    this.child,
  });

  @override
  State<GridBackground> createState() => _GridBackgroundState();
}

class _GridBackgroundState extends State<GridBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.animationDuration);
    if (widget.animated) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gridColor = widget.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.08));

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _GridPainter(
              gridStyle: widget.gridStyle,
              spacing: widget.spacing,
              color: gridColor,
              dotRadius: widget.dotRadius,
              animValue: _controller.value,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final GridStyle gridStyle;
  final double spacing;
  final Color color;
  final double dotRadius;
  final double animValue;

  _GridPainter({
    required this.gridStyle,
    required this.spacing,
    required this.color,
    required this.dotRadius,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    switch (gridStyle) {
      case GridStyle.dots:
        final r = dotRadius * (0.7 + animValue * 0.6);
        for (double x = 0; x <= size.width; x += spacing) {
          for (double y = 0; y <= size.height; y += spacing) {
            canvas.drawCircle(Offset(x, y), r, paint);
          }
        }
      case GridStyle.lines:
        paint.strokeWidth = 0.5;
        paint.style = PaintingStyle.stroke;
        for (double x = 0; x <= size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (double y = 0; y <= size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
      case GridStyle.crosshatch:
        paint.strokeWidth = 0.5;
        paint.style = PaintingStyle.stroke;
        for (double x = 0; x <= size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (double y = 0; y <= size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        final diagPaint = Paint()
          ..color = color.withValues(alpha: color.a * 0.5)
          ..strokeWidth = 0.3
          ..style = PaintingStyle.stroke;
        for (double d = -size.height; d <= size.width; d += spacing) {
          canvas.drawLine(
            Offset(d, 0),
            Offset(d + size.height, size.height),
            diagPaint,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.animValue != animValue;
}
