import 'package:flutter/material.dart';

class TableItemAttribute {
  String attribute;
  dynamic value;
  Color? textColor;
  Function()? child;
  bool isVisible;
  bool isEditable;
  bool isAlignToRight;

  TableItemAttribute({
    required this.attribute,
    required this.value,
    this.child,
    this.textColor,
    this.isVisible = true,
    this.isEditable = false,
    this.isAlignToRight = false,
  });
}
