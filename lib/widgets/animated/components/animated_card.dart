import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final double maxTiltDegrees;
  final double elevation;
  final BorderRadius? borderRadius;
  final Color? shadowColor;
  final Duration transitionDuration;
  final VoidCallback? onTap;

  const AnimatedCard({
    super.key,
    required this.child,
    this.maxTiltDegrees = 10.0,
    this.elevation = 8.0,
    this.borderRadius,
    this.shadowColor,
    this.transitionDuration = const Duration(milliseconds: 200),
    this.onTap,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  double _rotateX = 0;
  double _rotateY = 0;
  double _scale = 1.0;

  void _onHover(PointerEvent event) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final relX = (event.localPosition.dx / size.width - 0.5) * 2;
    final relY = (event.localPosition.dy / size.height - 0.5) * 2;
    final maxRad = widget.maxTiltDegrees * math.pi / 180;
    setState(() {
      _rotateX = relY * -maxRad;
      _rotateY = relX * maxRad;
      _scale = 1.03;
    });
  }

  void _onExit() {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    final shadowColor = widget.shadowColor ?? Colors.black;
    return MouseRegion(
      onHover: _onHover,
      onExit: (_) => _onExit(),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.97),
        onTapUp: (_) {
          setState(() => _scale = 1.0);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _scale = 1.0),
        child: AnimatedContainer(
          duration: widget.transitionDuration,
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_rotateX)
            ..rotateY(_rotateY)
            ..scaleByDouble(_scale, _scale, 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.15),
                blurRadius: widget.elevation * 2,
                offset: Offset(_rotateY * 6, _rotateX * -6),
              ),
            ],
          ),
          child: ClipRRect(borderRadius: radius, child: widget.child),
        ),
      ),
    );
  }
}
