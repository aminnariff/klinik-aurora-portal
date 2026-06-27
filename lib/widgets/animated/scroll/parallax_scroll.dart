import 'package:flutter/material.dart';

/// Wraps [child] and translates it at [factor] × the scroll offset.
///
/// [factor] < 1.0 makes the child scroll slower than the viewport (classic parallax).
/// [factor] > 1.0 makes it scroll faster.
/// Negative values invert the direction.
class ParallaxScroll extends StatefulWidget {
  final Widget child;
  final double factor;
  final Axis axis;

  const ParallaxScroll({
    super.key,
    required this.child,
    this.factor = 0.4,
    this.axis = Axis.vertical,
  });

  @override
  State<ParallaxScroll> createState() => _ParallaxScrollState();
}

class _ParallaxScrollState extends State<ParallaxScroll> {
  ScrollPosition? _scrollPosition;
  double _offset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_onScroll);
    final scrollable = Scrollable.maybeOf(context);
    _scrollPosition = scrollable?.position;
    _scrollPosition?.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() => _offset = (_scrollPosition?.pixels ?? 0) * widget.factor);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dx = widget.axis == Axis.horizontal ? _offset : 0.0;
    final dy = widget.axis == Axis.vertical ? _offset : 0.0;
    return Transform.translate(
      offset: Offset(dx, dy),
      child: widget.child,
    );
  }
}
