import 'package:flutter/material.dart';

class DialogButtonAttribute {
  String? text;
  Function()? action;
  Color? color;
  Color? textColor;

  DialogButtonAttribute(
    this.action, {
    this.text,
    this.color,
    this.textColor,
  });
}
