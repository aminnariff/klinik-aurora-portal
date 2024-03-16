import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_button_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_type.dart';
import 'package:flutter/material.dart';

class DialogAttribute {
  String? title;
  String? text;
  Widget? logo;
  Widget? textWidget;
  List<DialogButtonAttribute>? buttonAttributes;
  DialogType type;
  DialogButtonAttribute? cancelButton;
  double? width;
  double? height;

  DialogAttribute({
    this.title,
    this.text,
    this.logo,
    this.textWidget,
    this.type = DialogType.error,
    this.buttonAttributes,
    this.cancelButton,
    this.width,
    this.height,
  });
}
