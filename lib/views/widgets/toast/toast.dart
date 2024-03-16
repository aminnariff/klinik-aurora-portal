import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum ToastType {
  error,
  info,
}

abstract class AppToast {
  static show(String message, {ToastType type = ToastType.error}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: ToastType.error == type ? Colors.red : Colors.white,
      textColor: Colors.white,
      fontSize: 16.0,
      webBgColor: type == ToastType.error
          ? "linear-gradient(to right, red, red)"
          : "linear-gradient(to right, #53006A, #9200BA)",
      webPosition: 'right',
    );
  }

  static snackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outlined,
              color: Colors.red,
            ),
            AppPadding.horizontal(),
            Expanded(
              child: AppSelectableText(
                message,
                style: AppTypography.bodyMedium(context).apply(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
