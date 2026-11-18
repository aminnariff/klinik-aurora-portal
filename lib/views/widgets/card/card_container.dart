import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';

class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final double? borderRadius;
  final Function()? action;

  const CardContainer(
    this.child, {
    super.key,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = borderRadius ?? 8.0;
    final card = Card(
      surfaceTintColor: Colors.transparent,
      elevation: elevation ?? 0.0,
      color: color ?? colors.surface,
      margin: margin ?? EdgeInsets.all(screenPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: colors.border),
      ),
      child: action != null
          ? InkWell(
              onTap: action,
              borderRadius: BorderRadius.circular(radius),
              child: child,
            )
          : child,
    );
    return card;
  }
}
