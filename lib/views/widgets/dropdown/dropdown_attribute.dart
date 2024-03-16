import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class DropdownAttributeList {
  final List<DropdownAttribute> items;
  final String? attribute;
  String? value;
  final String? hintText;
  final String? labelText;
  final String? helpText;
  TextAlign? helpTextAlign;
  String? errorMessage;
  final bool isEditable;
  Function(DropdownAttribute?)? onChanged;
  double? width;
  ButtonStyleData? buttonStyleData;
  Color? fieldColor;
  Color? borderColor;
  bool? titleCase;

  DropdownAttributeList(
    this.items, {
    this.attribute,
    this.value,
    this.hintText,
    this.labelText,
    this.helpText,
    this.helpTextAlign,
    this.errorMessage,
    this.isEditable = true,
    required this.onChanged,
    this.width,
    this.buttonStyleData,
    this.fieldColor,
    this.borderColor,
    this.titleCase = false,
  });
}

class DropdownAttribute {
  final String key;
  final String name;
  final String? description;
  final String? logo;

  DropdownAttribute(
    this.key,
    this.name, {
    this.description,
    this.logo,
  });
}
