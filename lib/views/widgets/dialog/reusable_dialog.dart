import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/confirmation_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/confirmation_dialog_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_button_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_type.dart';

showDialogError(BuildContext context, String text) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppDialog(
          DialogAttribute(text: text, type: DialogType.error),
        );
      });
}

showDialogSuccess(BuildContext context, String text) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppDialog(
          DialogAttribute(text: text, type: DialogType.success),
        );
      });
}

Future<bool> showConfirmDialog(BuildContext context, String bodyText) async {
  return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          ConfirmationDialogAttribute(
            type: DialogType.info,
            logo: SvgPicture.asset(
              'assets/icons/failed/warning.svg',
              height: 120,
              colorFilter: const ColorFilter.mode(secondaryColor, BlendMode.srcIn),
            ),
            text: bodyText,
            confrimButton: DialogButtonAttribute(
              () {
                context.pop(true);
              },
              text: 'Confirm',
              color: secondaryColor,
              textColor: Colors.white,
            ),
            cancelButton: DialogButtonAttribute(
              () {
                context.pop(false);
              },
              text: 'Cancel',
              color: const Color(0XFFEAEAEA),
              textColor: textPrimaryColor,
            ),
          ),
        );
      });
}
