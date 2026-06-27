import 'package:flutter/material.dart';

class CountingText extends StatefulWidget {
  final double from;
  final double to;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final bool autoPlay;
  final String prefix;
  final String suffix;
  final int decimalPlaces;
  final String Function(double value)? formatter;
  final VoidCallback? onComplete;

  const CountingText({
    super.key,
    required this.from,
    required this.to,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeOutCubic,
    this.autoPlay = true,
    this.prefix = '',
    this.suffix = '',
    this.decimalPlaces = 0,
    this.formatter,
    this.onComplete,
  });

  @override
  State<CountingText> createState() => _CountingTextState();
}

class _CountingTextState extends State<CountingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: widget.from, end: widget.to).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    if (widget.autoPlay) {
      _controller.forward().then((_) => widget.onComplete?.call());
    }
  }

  void play() {
    _controller.reset();
    _controller.forward().then((_) => widget.onComplete?.call());
  }

  void reset() => _controller.reset();

  String _formatValue(double value) {
    if (widget.formatter != null) return widget.formatter!(value);
    if (widget.decimalPlaces == 0) return value.round().toString();
    return value.toStringAsFixed(widget.decimalPlaces);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Text(
        '${widget.prefix}${_formatValue(_animation.value)}${widget.suffix}',
        style: widget.style,
      ),
    );
  }
}
