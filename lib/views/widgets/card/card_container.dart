import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:flutter/material.dart';

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
    return GestureDetector(
      onTap: action,
      child: Card(
        surfaceTintColor: Colors.white,
        elevation: elevation ?? 5.0,
        color: color ?? Colors.white,
        margin: margin ?? EdgeInsets.all(screenPadding),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius ?? 15)),
        child: child,
      ),
    );
  }
}
