import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final Color glitchColor1;
  final Color glitchColor2;
  final Duration glitchInterval;
  final Duration glitchDuration;
  final bool autoPlay;

  const GlitchText({
    super.key,
    required this.text,
    this.style,
    this.color,
    this.glitchColor1 = const Color(0xFFFF0055),
    this.glitchColor2 = const Color(0xFF00FFFF),
    this.glitchInterval = const Duration(seconds: 3),
    this.glitchDuration = const Duration(milliseconds: 300),
    this.autoPlay = true,
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> {
  final _random = Random();
  Timer? _intervalTimer;
  Timer? _glitchTimer;
  bool _isGlitching = false;
  double _offset1 = 0;
  double _offset2 = 0;
  double _vertOffset = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) _startInterval();
  }

  void _startInterval() {
    _intervalTimer?.cancel();
    _intervalTimer = Timer.periodic(widget.glitchInterval, (_) {
      if (mounted) _triggerGlitch();
    });
    // First glitch after a short initial delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _triggerGlitch();
    });
  }

  void _triggerGlitch() {
    int ticks = 0;
    final totalTicks = (widget.glitchDuration.inMilliseconds / 40).ceil();
    _glitchTimer?.cancel();
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      ticks++;
      if (ticks >= totalTicks) {
        timer.cancel();
        setState(() {
          _isGlitching = false;
          _offset1 = 0;
          _offset2 = 0;
          _vertOffset = 0;
        });
      } else {
        setState(() {
          _isGlitching = true;
          _offset1 = (_random.nextDouble() - 0.5) * 10;
          _offset2 = (_random.nextDouble() - 0.5) * -10;
          _vertOffset = (_random.nextDouble() - 0.5) * 2;
        });
      }
    });
  }

  void triggerGlitch() => _triggerGlitch();

  @override
  void dispose() {
    _intervalTimer?.cancel();
    _glitchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? const TextStyle(fontSize: 24);
    final primaryColor = widget.color ??
        (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black);

    if (!_isGlitching) {
      return Text(widget.text, style: baseStyle.copyWith(color: primaryColor));
    }

    return Stack(
      children: [
        Transform.translate(
          offset: Offset(_offset1, _vertOffset),
          child: Text(
            widget.text,
            style: baseStyle.copyWith(color: widget.glitchColor1.withValues(alpha: 0.75)),
          ),
        ),
        Transform.translate(
          offset: Offset(_offset2, -_vertOffset),
          child: Text(
            widget.text,
            style: baseStyle.copyWith(color: widget.glitchColor2.withValues(alpha: 0.75)),
          ),
        ),
        Text(widget.text, style: baseStyle.copyWith(color: primaryColor)),
      ],
    );
  }
}
