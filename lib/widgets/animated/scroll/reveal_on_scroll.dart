import 'package:flutter/material.dart';

enum RevealDirection { fromBottom, fromTop, fromLeft, fromRight, fade }

class RevealOnScroll extends StatefulWidget {
  final Widget child;
  final RevealDirection direction;
  final Duration duration;
  final Curve curve;
  final double slideDistance;
  final bool repeat;

  const RevealOnScroll({
    super.key,
    required this.child,
    this.direction = RevealDirection.fromBottom,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
    this.slideDistance = 40.0,
    this.repeat = false,
  });

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _hasRevealed = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _slideAnim = Tween<Offset>(begin: _beginOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  Offset get _beginOffset {
    final d = widget.slideDistance / 500;
    switch (widget.direction) {
      case RevealDirection.fromBottom:
        return Offset(0, d);
      case RevealDirection.fromTop:
        return Offset(0, -d);
      case RevealDirection.fromLeft:
        return Offset(-d, 0);
      case RevealDirection.fromRight:
        return Offset(d, 0);
      case RevealDirection.fade:
        return Offset.zero;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_checkVisibility);
    final scrollable = Scrollable.maybeOf(context);
    _scrollPosition = scrollable?.position;
    _scrollPosition?.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;
    final globalPos = renderBox.localToGlobal(Offset.zero);
    final screenH = MediaQuery.sizeOf(context).height;
    final isVisible = globalPos.dy < screenH * 0.92 &&
        globalPos.dy + renderBox.size.height > 0;

    if (isVisible && !_hasRevealed) {
      _hasRevealed = true;
      _controller.forward();
    } else if (!isVisible && widget.repeat && _hasRevealed) {
      _hasRevealed = false;
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}
