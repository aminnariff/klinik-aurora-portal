import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_button_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_type.dart';
import 'package:flutter/material.dart';

class ConfirmationDialogAttribute {
  String? title;
  String? text;
  Widget? logo;
  Widget? textWidget;
  DialogType type;
  DialogButtonAttribute? confrimButton;
  DialogButtonAttribute? cancelButton;
  double? width;
  double? height;

  ConfirmationDialogAttribute({
    this.title,
    this.text,
    this.logo,
    this.textWidget,
    this.type = DialogType.success,
    this.confrimButton,
    this.cancelButton,
    this.width,
    this.height,
  });
}
