import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final Duration duration;
  final TextStyle? digitStyle;
  final TextStyle? labelStyle;
  final VoidCallback? onComplete;
  final bool autoPlay;
  final Color? color;
  final bool showHours;
  final bool showLabels;

  const CountdownTimer({
    super.key,
    required this.duration,
    this.digitStyle,
    this.labelStyle,
    this.onComplete,
    this.autoPlay = true,
    this.color,
    this.showHours = false,
    this.showLabels = true,
  });

  @override
  State<CountdownTimer> createState() => CountdownTimerState();
}

class CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  late Duration _remaining;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    if (widget.autoPlay) start();
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining.inSeconds <= 0) {
        timer.cancel();
        _isRunning = false;
        widget.onComplete?.call();
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
  }

  void reset() {
    pause();
    setState(() => _remaining = widget.duration);
  }

  void restart() {
    reset();
    start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);

    final segments = widget.showHours ? [h, m, s] : [m, s];
    final labels = widget.showHours ? ['h', 'm', 's'] : ['m', 's'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          _DigitBlock(
            value: segments[i],
            label: widget.showLabels ? labels[i] : null,
            digitStyle: widget.digitStyle,
            labelStyle: widget.labelStyle,
            color: widget.color,
          ),
          if (i < segments.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                ':',
                style: (widget.digitStyle ??
                        const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ))
                    .copyWith(color: widget.color),
              ),
            ),
        ],
      ],
    );
  }
}

class _DigitBlock extends StatelessWidget {
  final int value;
  final String? label;
  final TextStyle? digitStyle;
  final TextStyle? labelStyle;
  final Color? color;

  const _DigitBlock({
    required this.value,
    this.label,
    this.digitStyle,
    this.labelStyle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = digitStyle ??
        const TextStyle(fontSize: 32, fontWeight: FontWeight.bold);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.6),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            key: ValueKey(value),
            style: baseStyle.copyWith(color: color),
          ),
        ),
        if (label != null)
          Text(
            label!,
            style: (labelStyle ??
                    TextStyle(
                      fontSize: 10,
                      color: (color ?? Theme.of(context).textTheme.bodyMedium?.color)
                          ?.withValues(alpha: 0.55),
                    ))
                .copyWith(
              color: (color ?? Theme.of(context).textTheme.bodyMedium?.color)
                  ?.withValues(alpha: 0.55),
            ),
          ),
      ],
    );
  }
}
