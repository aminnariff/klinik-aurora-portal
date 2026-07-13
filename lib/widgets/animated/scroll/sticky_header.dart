import 'package:flutter/material.dart';

/// A ready-made [CustomScrollView] with a sticky, optionally shrinking header.
///
/// Use [StickyHeaderSliver] when you need to embed this inside an existing
/// [CustomScrollView] instead.
class StickyHeader extends StatelessWidget {
  final Widget header;
  final double expandedHeight;
  final double collapsedHeight;
  final List<Widget> slivers;
  final bool shrink;
  final Color? backgroundColor;
  final Widget? background;
  final EdgeInsetsGeometry? headerPadding;

  const StickyHeader({
    super.key,
    required this.header,
    required this.slivers,
    this.expandedHeight = 120.0,
    this.collapsedHeight = 56.0,
    this.shrink = true,
    this.backgroundColor,
    this.background,
    this.headerPadding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            child: header,
            expandedHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
            shrink: shrink,
            backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
            background: background,
            padding: headerPadding ?? const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        ...slivers,
      ],
    );
  }
}

/// Use this sliver directly inside your own [CustomScrollView].
class StickyHeaderSliver extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double expandedHeight;
  final double collapsedHeight;
  final Color? backgroundColor;

  StickyHeaderSliver({
    required this.child,
    this.expandedHeight = 120.0,
    this.collapsedHeight = 56.0,
    this.backgroundColor,
  });

  @override
  double get minExtent => collapsedHeight;
  @override
  double get maxExtent => expandedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return Container(
      color: (backgroundColor ?? Theme.of(context).scaffoldBackgroundColor).withValues(alpha: 0.95),
      child: Opacity(
        opacity: 1 - progress * 0.3,
        child: Transform.scale(scale: 1 - progress * 0.05, alignment: Alignment.centerLeft, child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(StickyHeaderSliver old) =>
      old.expandedHeight != expandedHeight || old.collapsedHeight != collapsedHeight;
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double expandedHeight;
  final double collapsedHeight;
  final bool shrink;
  final Color backgroundColor;
  final Widget? background;
  final EdgeInsetsGeometry padding;

  _StickyHeaderDelegate({
    required this.child,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.shrink,
    required this.backgroundColor,
    required this.padding,
    this.background,
  });

  @override
  double get minExtent => collapsedHeight;
  @override
  double get maxExtent => shrink ? expandedHeight : collapsedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = ((shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0));
    return Container(
      color: backgroundColor.withValues(alpha: 0.97),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ?background,
          Padding(
            padding: padding,
            child: Align(
              alignment: AlignmentTween(begin: Alignment.bottomLeft, end: Alignment.centerLeft).lerp(progress),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate old) => old.expandedHeight != expandedHeight || old.shrink != shrink;
}
