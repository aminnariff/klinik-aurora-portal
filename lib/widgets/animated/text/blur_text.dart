import 'dart:ui';
import 'package:flutter/material.dart';

class BlurText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double initialBlur;
  final Duration duration;
  final bool autoPlay;
  final bool repeat;
  final VoidCallback? onComplete;

  const BlurText({
    super.key,
    required this.text,
    this.style,
    this.initialBlur = 10.0,
    this.duration = const Duration(milliseconds: 800),
    this.autoPlay = true,
    this.repeat = false,
    this.onComplete,
  });

  @override
  State<BlurText> createState() => _BlurTextState();
}

class _BlurTextState extends State<BlurText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blurAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _blurAnim = Tween<double>(begin: widget.initialBlur, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    if (widget.autoPlay) _play();
  }

  void _play() {
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward().then((_) => widget.onComplete?.call());
    }
  }

  void play() {
    _controller.reset();
    _play();
  }

  void reset() => _controller.reset();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacityAnim.value,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: _blurAnim.value,
            sigmaY: _blurAnim.value,
          ),
          child: child,
        ),
      ),
      child: Text(widget.text, style: widget.style),
    );
  }
}
