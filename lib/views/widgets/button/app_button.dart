import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';

enum AppButtonVariant { primary, secondary, destructive }

/// Standardized action button for Klinik Aurora Portal.
///
/// Variants:
/// - [AppButton.primary]: Active brand primary (default Aurora Plum #7E2D40) filled, white text
/// - [AppButton.secondary]: Surface background, subtle border, secondary ink text
/// - [AppButton.destructive]: Red filled, white text
///
/// All buttons enforce 8px corner radius, Emil scale(0.97) micro-interactions,
/// light/dark theme adaptation, and integrated loading state.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;
  final EdgeInsets? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 40.0,
    this.padding,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 40.0,
    this.padding,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 40.0,
    this.padding,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.destructive({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 40.0,
    this.padding,
  }) : variant = AppButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final colors = context.appColors;

    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = colors.brandPrimary;
        fg = colors.brandOnPrimary;
        border = null;
        break;
      case AppButtonVariant.secondary:
        bg = colors.surface;
        fg = colors.inkSecondary;
        border = BorderSide(color: colors.borderStrong, width: 1.0);
        break;
      case AppButtonVariant.destructive:
        bg = const Color(0xFFDC2626);
        fg = Colors.white;
        border = null;
        break;
    }

    final effectivePadding = padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 10);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isEnabled ? fg : fg.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );

    return EmilPressable(
      onTap: isEnabled ? onPressed : null,
      enabled: isEnabled,
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: bg.withValues(alpha: 0.4),
            disabledForegroundColor: fg.withValues(alpha: 0.5),
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: border ?? BorderSide.none,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
