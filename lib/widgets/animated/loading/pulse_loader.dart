import 'package:flutter/material.dart';

class PulseLoader extends StatefulWidget {
  final Color? color;
  final double size;
  final int pulseCount;
  final Duration duration;
  final Duration staggerDelay;
  final bool autoPlay;

  const PulseLoader({
    super.key,
    this.color,
    this.size = 48.0,
    this.pulseCount = 3,
    this.duration = const Duration(milliseconds: 1200),
    this.staggerDelay = const Duration(milliseconds: 200),
    this.autoPlay = true,
  });

  @override
  State<PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<PulseLoader> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnims;
  late List<Animation<double>> _opacityAnims;

  @override
  void initState() {
    super.initState();
    _buildAnimations();
    if (widget.autoPlay) _play();
  }

  void _buildAnimations() {
    _controllers = List.generate(
      widget.pulseCount,
      (_) => AnimationController(vsync: this, duration: widget.duration),
    );
    _scaleAnims = _controllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOut),
            ))
        .toList();
    _opacityAnims = _controllers
        .map((c) => Tween<double>(begin: 0.7, end: 0.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOut),
            ))
        .toList();
  }

  void _play() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(widget.staggerDelay);
      if (mounted) _controllers[i].repeat();
    }
  }

  void start() => _play();
  void stop() {
    for (final c in _controllers) {
      c.stop();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple rings
          ...List.generate(widget.pulseCount, (i) {
            return AnimatedBuilder(
              animation: _controllers[i],
              builder: (context, _) => Opacity(
                opacity: _opacityAnims[i].value,
                child: Transform.scale(
                  scale: _scaleAnims[i].value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          // Core dot
          Container(
            width: widget.size * 0.2,
            height: widget.size * 0.2,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
