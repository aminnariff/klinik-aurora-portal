import 'package:flutter/material.dart';

class SearchingAttribute {
  String attribute;
  TextEditingController controller;
  bool isDropdown;
  String? label;
  String? queryType;
  String? errorMessage;
  bool visible;
  SearchingAttribute({
    required this.attribute,
    required this.controller,
    this.isDropdown = false,
    this.label,
    this.queryType,
    this.errorMessage,
    this.visible = true,
  });
}
