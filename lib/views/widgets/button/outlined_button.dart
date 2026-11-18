import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';

class AppOutlinedButton extends StatefulWidget {
  final Function() onPressed;
  final bool enableFeedback;
  final Color? backgroundColor;
  final double? borderRadius;
  final double? width;
  final double? height;
  final String? text;
  final Widget? widget;

  const AppOutlinedButton(
    this.onPressed, {
    super.key,
    this.backgroundColor,
    this.borderRadius,
    this.width,
    this.height,
    this.enableFeedback = true,
    this.text,
    this.widget,
  });

  @override
  State<AppOutlinedButton> createState() => _AppOutlinedButtonState();
}

class _AppOutlinedButtonState extends State<AppOutlinedButton> {
  bool _isPressed = false;

  void _setPressed(bool val) {
    if (_isPressed != val) {
      setState(() => _isPressed = val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: (!reducedMotion && _isPressed) ? 0.97 : 1.0,
      duration: reducedMotion
          ? Duration.zero
          : (_isPressed ? EmilMotion.pressDuration : EmilMotion.releaseDuration),
      curve: EmilMotion.easeOut,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Listener(
          onPointerDown: (_) => _setPressed(true),
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: OutlinedButton(
            onPressed: widget.onPressed,
            style: OutlinedButton.styleFrom(
              elevation: 0.0,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              enableFeedback: widget.enableFeedback,
              backgroundColor: widget.backgroundColor ?? colors.surface,
              foregroundColor: colors.inkSecondary,
              side: BorderSide(color: colors.borderStrong),
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.0),
              ),
            ),
            child: widget.widget ??
                Text(
                  widget.text ?? 'Okay',
                  style: TextStyle(color: colors.inkPrimary, fontWeight: FontWeight.w600),
                ),
          ),
        ),
      ),
    );
  }
}
