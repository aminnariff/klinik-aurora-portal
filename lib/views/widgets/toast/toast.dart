import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';

enum ToastType { error, info, success }

abstract class AppToast {
  static void show(String message, {ToastType type = ToastType.error}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: type == ToastType.error
          ? Colors.red
          : (type == ToastType.success ? const Color(0xFF10B981) : Colors.white),
      textColor: Colors.white,
      fontSize: 16.0,
      webBgColor: type == ToastType.error
          ? "linear-gradient(to right, #EF4444, #EF4444)"
          : (type == ToastType.success
              ? "linear-gradient(to right, #10B981, #059669)"
              : "linear-gradient(to right, #53006A, #9200BA)"),
      webPosition: 'right',
    );
  }

  /// Modern floating notification following Emil Kowalski's Sonner principles:
  /// - Interruptible (clears prior bar immediately)
  /// - Floating surface with spatial padding
  /// - Semantic icon styling (success green vs error red)
  static void snackbar(BuildContext context, String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 12,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isError ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppSelectableText(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
