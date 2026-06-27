import 'package:flutter/material.dart';

enum SplitType { chars, words }

class SplitText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final SplitType splitType;
  final Duration staggerDelay;
  final Duration duration;
  final bool autoPlay;
  final bool repeat;
  final VoidCallback? onComplete;
  final Offset slideOffset;

  const SplitText({
    super.key,
    required this.text,
    this.style,
    this.splitType = SplitType.chars,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.autoPlay = true,
    this.repeat = false,
    this.onComplete,
    this.slideOffset = const Offset(0, 20),
  });

  @override
  State<SplitText> createState() => _SplitTextState();
}

class _SplitTextState extends State<SplitText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _opacityAnims;
  late List<Animation<double>> _slideAnims;
  late List<String> _parts;

  @override
  void initState() {
    super.initState();
    _parts = widget.splitType == SplitType.chars
        ? widget.text.split('')
        : widget.text.split(' ');
    _buildAnimations();
    if (widget.autoPlay) _play();
  }

  void _buildAnimations() {
    final staggerMs = widget.staggerDelay.inMilliseconds;
    final durationMs = widget.duration.inMilliseconds;
    final n = _parts.length;
    final totalMs = (n - 1) * staggerMs + durationMs;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    _opacityAnims = List.generate(n, (i) {
      final start = totalMs == 0 ? 0.0 : (i * staggerMs) / totalMs;
      final end = totalMs == 0 ? 1.0 : ((i * staggerMs + durationMs) / totalMs).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeOut)),
      );
    });

    _slideAnims = List.generate(n, (i) {
      final start = totalMs == 0 ? 0.0 : (i * staggerMs) / totalMs;
      final end = totalMs == 0 ? 1.0 : ((i * staggerMs + durationMs) / totalMs).clamp(0.0, 1.0);
      return Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeOut)),
      );
    });
  }

  void _play() {
    if (widget.repeat) {
      _controller.repeat();
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
    return Wrap(
      children: List.generate(_parts.length, (i) {
        final displayText = widget.splitType == SplitType.words && i < _parts.length - 1
            ? '${_parts[i]} '
            : _parts[i];
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _opacityAnims[i].value,
            child: Transform.translate(
              offset: Offset(
                widget.slideOffset.dx * _slideAnims[i].value,
                widget.slideOffset.dy * _slideAnims[i].value,
              ),
              child: child,
            ),
          ),
          child: Text(displayText, style: widget.style),
        );
      }),
    );
  }
}
