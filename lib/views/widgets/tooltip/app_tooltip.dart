import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  const AppTooltip({super.key, required this.message, required this.child});

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? Tooltip(
            message: message,
            preferBelow: false, // Show tooltip above the button on the web
            verticalOffset: 24,
            child: child, // Adjust the distance of the tooltip from the button
          )
        : GestureDetector(
            onTap: () {
              showTooltip(context);
            },
            onLongPress: () {
              showTooltip(context);
            },
            child: child,
          );
  }

  void showTooltip(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        child: Material(
          color: Colors.transparent,
          child: Tooltip(
            message: message,
            preferBelow: false,
            verticalOffset: 24,
            child: child,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
