import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ScrambleText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charRevealDelay;
  final bool autoPlay;
  final bool repeat;
  final Duration repeatDelay;
  final VoidCallback? onComplete;
  final String scrambleChars;

  const ScrambleText({
    super.key,
    required this.text,
    this.style,
    this.charRevealDelay = const Duration(milliseconds: 60),
    this.autoPlay = true,
    this.repeat = false,
    this.repeatDelay = const Duration(seconds: 2),
    this.onComplete,
    this.scrambleChars =
        r'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*',
  });

  @override
  State<ScrambleText> createState() => _ScrambleTextState();
}

class _ScrambleTextState extends State<ScrambleText> {
  final _random = Random();
  String _displayText = '';
  Timer? _scrambleTimer;
  Timer? _revealTimer;
  int _revealedCount = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _displayText = _randomString(widget.text.length);
    if (widget.autoPlay) _start();
  }

  String _randomString(int length) {
    return String.fromCharCodes(
      List.generate(length, (i) {
        if (i < widget.text.length && widget.text[i] == ' ') return 32;
        return widget.scrambleChars[_random.nextInt(widget.scrambleChars.length)]
            .codeUnitAt(0);
      }),
    );
  }

  void _start() {
    _revealedCount = 0;
    _isRunning = true;
    _scrambleTimer?.cancel();
    _revealTimer?.cancel();

    _scrambleTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted || !_isRunning) return;
      setState(() {
        _displayText = String.fromCharCodes(
          widget.text.codeUnits.asMap().entries.map((e) {
            final i = e.key;
            if (i < _revealedCount) return widget.text.codeUnitAt(i);
            if (widget.text[i] == ' ') return 32;
            return widget.scrambleChars[_random.nextInt(widget.scrambleChars.length)]
                .codeUnitAt(0);
          }),
        );
      });
    });

    _revealTimer = Timer.periodic(widget.charRevealDelay, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _revealedCount++;
      if (_revealedCount >= widget.text.length) {
        timer.cancel();
        _scrambleTimer?.cancel();
        _isRunning = false;
        if (mounted) setState(() => _displayText = widget.text);
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

  @override
  void dispose() {
    _scrambleTimer?.cancel();
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayText, style: widget.style);
  }
}
