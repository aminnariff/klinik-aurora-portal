import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';

class Button extends StatefulWidget {
  final Function()? action;
  final String actionText;
  final MainAxisSize mainAxisSize;
  final double? height;
  final double? width;
  final double? borderRadius;
  final double? elevation;
  final EdgeInsets? margin;
  final Widget? icon;
  final Color? color;
  final Gradient? gradient;
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
    this.gradient,
    this.color,
    this.isFlexible = false,
    this.textColor,
    this.containerVerticalPadding,
  });

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  bool _isPressed = false;

  void _setPressed(bool val) {
    if (widget.action == null) return;
    if (_isPressed != val) {
      setState(() => _isPressed = val);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final effectiveBorderRadius = widget.borderRadius ?? 8.0;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveGradient = widget.gradient ??
        LinearGradient(colors: primaryColors, begin: Alignment.topLeft, end: Alignment.bottomRight);
    return AnimatedScale(
      scale: (!reducedMotion && _isPressed) ? 0.97 : 1.0,
      duration: reducedMotion
          ? Duration.zero
          : (_isPressed ? EmilMotion.pressDuration : EmilMotion.releaseDuration),
      curve: EmilMotion.easeOut,
      child: Container(
        padding: widget.margin ?? EdgeInsets.symmetric(vertical: isMobile ? widget.containerVerticalPadding ?? 0 : 0),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: widget.action == null
              ? LinearGradient(colors: [appBorder, appBorder])
              : (widget.color != null)
              ? LinearGradient(colors: [widget.color!, widget.color!], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : effectiveGradient,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
        ),
        child: Listener(
          onPointerDown: (_) => _setPressed(true),
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: ElevatedButton(
            onPressed: widget.action,
            onHover: (value) {},
            style: ElevatedButton.styleFrom(
              elevation: widget.elevation ?? 10.0,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: widget.padding ?? EdgeInsets.symmetric(horizontal: screenPadding, vertical: 25),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(effectiveBorderRadius)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 8),
                ],
                buttonText(
                  Text(
                    widget.actionText,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.apply(color: widget.textColor ?? Colors.white, fontWeightDelta: 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buttonText(Widget child) {
    return widget.isFlexible ? Flexible(child: child) : child;
  }
}
