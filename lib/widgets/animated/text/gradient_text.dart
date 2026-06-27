import 'package:flutter/material.dart';

class GradientText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final List<Color> colors;
  final Duration duration;
  final bool autoPlay;
  final bool repeat;

  const GradientText({
    super.key,
    required this.text,
    this.style,
    this.colors = const [Color(0xFF6C63FF), Color(0xFF00D4FF), Color(0xFF6C63FF)],
    this.duration = const Duration(milliseconds: 2000),
    this.autoPlay = true,
    this.repeat = true,
  });

  @override
  State<GradientText> createState() => _GradientTextState();
}

class _GradientTextState extends State<GradientText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.autoPlay) {
      widget.repeat ? _controller.repeat() : _controller.forward();
    }
  }

  void play() => widget.repeat ? _controller.repeat() : _controller.forward();
  void stop() => _controller.stop();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: widget.colors,
            stops: List.generate(
              widget.colors.length,
              (i) => i / (widget.colors.length - 1),
            ),
            begin: Alignment(-2 + t * 4, 0),
            end: Alignment(t * 4, 0),
          ).createShader(bounds),
          child: child,
        );
      },
      child: Text(
        widget.text,
        style: (widget.style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}
