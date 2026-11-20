import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../motion/emil_motion.dart';
import 'aurora_wave_mesh.dart';

class AuroraEmptyState extends StatelessWidget {
  const AuroraEmptyState({
    super.key,
    required this.icon,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.illustration,
    this.height = 120,
    this.textColor,
  });

  final IconData icon;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? illustration;
  final double height;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SizedBox(
            height: height,
            child: ClipRect(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AuroraWaveMesh(height: height, accentColor: colors.brandText),
                  illustration ?? Icon(icon, size: (height / 2).clamp(24, 56), color: colors.brandText),
                ],
              ),
            ),
          ),
        ),
        if (title != null)
          Text(title!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor ?? colors.inkSecondary),
            ),
          ),
        if (actionLabel != null && onAction != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: EmilPressable(
              onTap: onAction,
              child: FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ),
          ),
      ],
    );
  }
}
