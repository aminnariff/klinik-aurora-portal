import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/confirmation_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/confirmation_dialog_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_type.dart';

/// Shared dimmed barrier used by all app dialogs.
const Color dialogBarrierColor = Color(0x8C0F172A); // slate-900 @ 55%

bool _isErrorDialogVisible = false;
bool _isSuccessDialogVisible = false;

void showDialogError(BuildContext context, String text) {
  if (_isErrorDialogVisible) return;
  _isErrorDialogVisible = true;
  showDialog(
    context: context,
    barrierColor: dialogBarrierColor,
    builder: (BuildContext context) {
      return AppDialog(DialogAttribute(text: text, type: DialogType.error));
    },
  ).whenComplete(() {
    _isErrorDialogVisible = false;
  });
}

void showDialogSuccess(BuildContext context, String text) {
  if (_isSuccessDialogVisible) return;
  _isSuccessDialogVisible = true;
  showDialog(
    context: context,
    barrierColor: dialogBarrierColor,
    builder: (BuildContext context) {
      return AppDialog(DialogAttribute(text: text, type: DialogType.success));
    },
  ).whenComplete(() {
    _isSuccessDialogVisible = false;
  });
}

Future<bool> showConfirmDialog(BuildContext context, String bodyText, {String? title}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: dialogBarrierColor,
    builder: (BuildContext context) {
      return ConfirmationDialog(ConfirmationDialogAttribute(type: DialogType.info, title: title, text: bodyText));
    },
  );
  return result == true;
}
