import 'package:flutter/material.dart';

class LoginItem {
  String attribute;
  TextEditingController controller;
  String errorMessage;
  String hintText;
  bool isPassword;
  bool obscureText;
  String icon;

  LoginItem({
    required this.attribute,
    required this.controller,
    required this.errorMessage,
    required this.hintText,
    this.isPassword = false,
    required this.obscureText,
    required this.icon,
  });
}
