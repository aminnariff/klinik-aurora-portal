import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDelay;
  final bool showCursor;
  final String cursor;
  final bool autoPlay;
  final bool repeat;
  final Duration repeatDelay;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDelay = const Duration(milliseconds: 80),
    this.showCursor = true,
    this.cursor = '|',
    this.autoPlay = true,
    this.repeat = false,
    this.repeatDelay = const Duration(seconds: 1),
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  Timer? _typeTimer;
  int _displayedLength = 0;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
    if (widget.autoPlay) _start();
  }

  void _start() {
    _typeTimer?.cancel();
    setState(() => _displayedLength = 0);
    _typeTimer = Timer.periodic(widget.charDelay, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_displayedLength < widget.text.length) {
        setState(() => _displayedLength++);
      } else {
        timer.cancel();
        widget.onComplete?.call();
        if (widget.repeat) {
          Future.delayed(widget.repeatDelay, () {
            if (mounted) _start();
          });
        }
      }
    });
  }

  void play() => _start();

  void reset() {
    _typeTimer?.cancel();
    if (mounted) setState(() => _displayedLength = 0);
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text.substring(0, _displayedLength),
          style: widget.style,
        ),
        if (widget.showCursor)
          AnimatedBuilder(
            animation: _cursorController,
            builder: (context, _) => Opacity(
              opacity: _cursorController.value,
              child: Text(widget.cursor, style: widget.style),
            ),
          ),
      ],
    );
  }
}
