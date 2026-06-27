import 'package:flutter/material.dart';

class MagneticButton extends StatefulWidget {
  final Widget child;
  final double strength;
  final double radius;
  final Duration attractDuration;
  final Duration releaseDuration;
  final VoidCallback? onTap;

  const MagneticButton({
    super.key,
    required this.child,
    this.strength = 0.35,
    this.radius = 90.0,
    this.attractDuration = const Duration(milliseconds: 150),
    this.releaseDuration = const Duration(milliseconds: 500),
    this.onTap,
  });

  @override
  State<MagneticButton> createState() => _MagneticButtonState();
}

class _MagneticButtonState extends State<MagneticButton> {
  Offset _offset = Offset.zero;
  bool _isAttracted = false;

  void _onHover(PointerEvent event) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final center = Offset(size.width / 2, size.height / 2);
    final delta = event.localPosition - center;
    final distance = delta.distance;

    if (distance < widget.radius) {
      final factor = (1 - distance / widget.radius) * widget.strength;
      setState(() {
        _offset = delta * factor;
        _isAttracted = true;
      });
    } else {
      setState(() {
        _offset = Offset.zero;
        _isAttracted = false;
      });
    }
  }

  void _onExit() {
    setState(() {
      _offset = Offset.zero;
      _isAttracted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: (_) => _onExit(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _isAttracted ? widget.attractDuration : widget.releaseDuration,
          curve: _isAttracted ? Curves.easeOut : Curves.elasticOut,
          transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0),
          child: widget.child,
        ),
      ),
    );
  }
}
