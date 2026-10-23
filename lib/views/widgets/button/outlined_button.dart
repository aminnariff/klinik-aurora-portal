import 'package:flutter/material.dart';
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
    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: _isPressed ? EmilMotion.pressDuration : EmilMotion.releaseDuration,
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
            style: ElevatedButton.styleFrom(
              elevation: 10.0,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              enableFeedback: widget.enableFeedback,
              backgroundColor: widget.backgroundColor ?? Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 50),
              ),
            ),
            child: widget.widget ??
                Text(
                  widget.text ?? 'Okay',
                ),
          ),
        ),
      ),
    );
  }
}
