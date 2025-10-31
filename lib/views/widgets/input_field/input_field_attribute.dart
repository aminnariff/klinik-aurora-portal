import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/date_picker/single_date_picker.dart';

class InputFieldAttribute {
  String? attribute;
  TextEditingController controller;
  String? labelText;
  String? hintText;
  String? helpText;
  TextAlign? helpTextAlign;
  bool isPassword;
  bool obscureText;
  bool isEditable;
  bool isNumber;
  bool isUpperCase;
  bool isCurrency;
  bool isEmail;
  bool isAlphaNumericOnly;
  String? errorMessage;
  String? prefixText;
  String? tooltip;
  Widget? prefixIcon;
  int? lineNumber;
  int maxCharacter;
  Color isEditableColor;
  Color uneditableColor;
  Function(String)? onChanged;
  bool isDatePicker;
  String? dateFormat;
  DatePickerAttribute? datePickerAttribute;
  Function? onCancelDate;
  Function(String?)? datePickerAction;
  TextInputType? textInputType;
  String? Function(String?)? validator;
  Function(String)? onFieldSubmitted;
  String? Function()? obsecureAction;
  Widget? suffixWidget;
  FocusNode? focusNode;
  bool isTimePicker;

  InputFieldAttribute({
    this.attribute,
    required this.controller,
    this.labelText,
    this.helpText,
    this.helpTextAlign,
    this.hintText,
    this.isPassword = false,
    this.obscureText = false,
    this.isUpperCase = false,
    this.isEditable = true,
    this.tooltip,
    this.isNumber = false,
    this.isCurrency = false,
    this.isAlphaNumericOnly = false,
    this.isEmail = false,
    this.isTimePicker = false,
    this.prefixText,
    this.prefixIcon,
    this.errorMessage,
    this.lineNumber = 1,
    this.maxCharacter = 255,
    this.isEditableColor = textFormFieldEditableColor,
    this.uneditableColor = textFormFieldUneditableColor,
    this.onChanged,
    this.dateFormat,
    this.isDatePicker = false,
    this.datePickerAction,
    this.onCancelDate,
    this.datePickerAttribute,
    this.textInputType,
    this.validator,
    this.onFieldSubmitted,
    this.obsecureAction,
    this.suffixWidget,
    this.focusNode,
  });
}
