import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../glass/app_glass.dart';
import 'emil_motion.dart';

abstract final class AuroraInspectorDrawer {
  static Future<T?> show<T>(BuildContext context, {required String label, required WidgetBuilder builder}) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return showGeneralDialog<T>(
      context: context,
      barrierLabel: label,
      barrierDismissible: true,
      barrierColor: Colors.black45,
      transitionDuration: reduce ? Duration.zero : EmilMotion.pageDuration,
      pageBuilder: (context, _, _) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final drawerWidth = screenWidth < 600 ? screenWidth : (screenWidth < 520 ? screenWidth : 520.0);
        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: drawerWidth,
            height: double.infinity,
            child: AppGlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 0,
              blurSigma: 6,
              child: Material(
                type: MaterialType.transparency,
                child: SafeArea(
                  child: CallbackShortcuts(
                    bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop()},
                    child: Focus(
                      autofocus: true,
                      child: LayoutBuilder(
                        builder: (context, constraints) => MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(size: Size(constraints.maxWidth, MediaQuery.sizeOf(context).height)),
                          child: Builder(builder: builder),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) => reduce
          ? child
          : SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: EmilMotion.easeDrawer)),
              ),
              child: child,
            ),
    );
  }
}
