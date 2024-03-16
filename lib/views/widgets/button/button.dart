import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final Function() action;
  final String actionText;
  final MainAxisSize mainAxisSize;
  final double? height;
  final double? width;
  final double? borderRadius;
  final double? elevation;
  final EdgeInsets? margin;
  final Widget? icon;
  final Color? color;
  final Gradient gradient;
  final bool isFlexible;
  final Color? textColor;
  final EdgeInsets? padding;
  final double? containerVerticalPadding;

  const Button(
    this.action, {
    super.key,
    this.mainAxisSize = MainAxisSize.min,
    this.actionText = 'Okay',
    this.height,
    this.width,
    this.margin,
    this.borderRadius,
    this.icon,
    this.elevation,
    this.padding,
    this.gradient = const LinearGradient(
      colors: primaryColors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.color,
    this.isFlexible = false,
    this.textColor,
    this.containerVerticalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: margin ?? EdgeInsets.symmetric(vertical: isMobile ? containerVerticalPadding ?? 0 : 0),
      width: width,
      height: null,
      decoration: BoxDecoration(
        gradient: (color != null)
            ? LinearGradient(
                colors: [color!, color!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? 20.0),
      ),
      child: ElevatedButton(
        onPressed: action,
        onHover: (value) {},
        style: ElevatedButton.styleFrom(
          elevation: elevation ?? 10.0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: padding ?? EdgeInsets.symmetric(horizontal: screenPadding, vertical: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 20.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buttonText(Text(
              actionText,
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodyMedium!.apply(color: textColor ?? Colors.white, fontWeightDelta: 2),
            )),
          ],
        ),
      ),
    );
  }

  Widget buttonText(Widget child) {
    return isFlexible
        ? Flexible(
            child: child,
          )
        : child;
  }
}
