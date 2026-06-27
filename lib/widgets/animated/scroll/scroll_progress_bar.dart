import 'package:flutter/material.dart';

enum ProgressBarPosition { top, bottom }

class ScrollProgressBar extends StatefulWidget {
  final Widget child;
  final ScrollController? scrollController;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final ProgressBarPosition position;
  final BorderRadius? borderRadius;

  const ScrollProgressBar({
    super.key,
    required this.child,
    this.scrollController,
    this.color,
    this.backgroundColor,
    this.height = 3.0,
    this.position = ProgressBarPosition.top,
    this.borderRadius,
  });

  @override
  State<ScrollProgressBar> createState() => _ScrollProgressBarState();
}

class _ScrollProgressBarState extends State<ScrollProgressBar> {
  late ScrollController _controller;
  double _progress = 0;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _controller = widget.scrollController!;
    } else {
      _controller = ScrollController();
      _ownsController = true;
    }
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final max = pos.maxScrollExtent;
    if (max <= 0) return;
    setState(() => _progress = (pos.pixels / max).clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final bar = _ProgressBar(
      progress: _progress,
      color: barColor,
      backgroundColor: widget.backgroundColor ?? Colors.transparent,
      height: widget.height,
      borderRadius: widget.borderRadius,
    );

    final scrollable = _ownsController
        ? SingleChildScrollView(
            controller: _controller,
            child: widget.child,
          )
        : widget.child;

    return Stack(
      children: [
        scrollable,
        Positioned(
          top: widget.position == ProgressBarPosition.top ? 0 : null,
          bottom: widget.position == ProgressBarPosition.bottom ? 0 : null,
          left: 0,
          right: 0,
          child: bar,
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadius? borderRadius;

  const _ProgressBar({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          color: backgroundColor,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: constraints.maxWidth * progress,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: borderRadius,
            ),
          ),
        );
      },
    );
  }
}
