import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable glassmorphic styling tokens and frosted container widgets.
class AppGlass {
  AppGlass._();

  /// Resolves frosted background fill based on brightness.
  static Color surfaceFill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xC7111B22) : const Color(0xE6FFFFFF);
  }

  /// Resolves hairline translucent border based on brightness.
  static Border hairlineBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Border.all(
      color: isDark ? const Color(0x1AFFFFFF) : const Color(0x140F172A),
      width: 1.0,
    );
  }

  /// Atmospheric elevation shadow for floating glass panels.
  static List<BoxShadow> elevationShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? const Color(0x66000000) : const Color(0x140F172A),
        blurRadius: 40,
        offset: const Offset(0, 16),
      ),
    ];
  }

  /// Input background fill for translucent form fields.
  static Color inputFill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xBF0E171E) : const Color(0xE6F8FAFC);
  }

  /// Input border for translucent form fields.
  static Border inputBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Border.all(
      color: isDark ? const Color(0x24FFFFFF) : const Color(0x1F0F172A),
      width: 1.0,
    );
  }
}

/// A frosted container with native [BackdropFilter], hairline border,
/// and atmospheric elevation shadows.
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final BoxConstraints? constraints;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 16.0,
    this.blurSigma = 18.0,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: constraints,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppGlass.elevationShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppGlass.surfaceFill(context),
              borderRadius: BorderRadius.circular(borderRadius),
              border: AppGlass.hairlineBorder(context),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
