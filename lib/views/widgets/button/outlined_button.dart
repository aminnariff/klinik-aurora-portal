import 'package:flutter/material.dart';

class AppOutlinedButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 10.0,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          enableFeedback: enableFeedback,
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 50),
          ),
        ),
        child: widget ??
            Text(
              text ?? 'Okay',
            ),
      ),
    );
  }
}
