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
  final bool auroraBorder;
  final bool enableBlur;
  final bool elevated;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 16.0,
    this.blurSigma = 18.0,
    this.constraints,
    this.auroraBorder = false,
    this.enableBlur = true,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget contents = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppGlass.surfaceFill(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: auroraBorder ? null : AppGlass.hairlineBorder(context),
      ),
      child: child,
    );
    if (enableBlur) {
      contents = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: contents,
      );
    }
    Widget cardBody = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: contents,
    );

    if (auroraBorder) {
      cardBody = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius + 1.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0x66DF6E98), // Rose
                    Color(0x26DF6E98),
                    Color(0x266AD1E3),
                    Color(0x556AD1E3), // Cyan
                  ]
                : const [
                    Color(0x4DDF6E98),
                    Color(0x1FDF6E98),
                    Color(0x1F6AD1E3),
                    Color(0x386AD1E3),
                  ],
            stops: const [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(1.0),
        child: cardBody,
      );
    }

    return Container(
      constraints: constraints,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevated ? AppGlass.elevationShadow(context) : null,
      ),
      child: cardBody,
    );
  }
}
