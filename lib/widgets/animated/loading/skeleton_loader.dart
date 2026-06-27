import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;

  const SkeletonLoader({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = baseColor ??
        (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0));
    final highlight = highlightColor ??
        (isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF5F5F5));

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: period,
      child: child,
    );
  }
}

/// A rounded rectangle bone — combine these to build skeleton layouts.
class SkeletonBone extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBone({
    super.key,
    this.width,
    this.height = 16.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      ),
    );
  }
}

/// Convenience: a skeleton that mimics a card with lines of text.
class SkeletonCard extends StatelessWidget {
  final double? width;
  final double height;
  final int lines;
  final bool hasImage;

  const SkeletonCard({
    super.key,
    this.width,
    this.height = 160.0,
    this.lines = 3,
    this.hasImage = true,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              Container(
                height: height * 0.45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...List.generate(lines, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SkeletonBone(
                width: i == lines - 1 ? 100 : null,
                height: 14,
              ),
            )),
          ],
        ),
      ),
    );
  }
}
