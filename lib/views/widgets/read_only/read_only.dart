import 'package:flutter/material.dart';

class ReadOnly extends StatelessWidget {
  final Widget widget;
  final bool isEditable;

  const ReadOnly(
    this.widget, {
    Key? key,
    required this.isEditable,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isEditable
        ? widget
        : AbsorbPointer(
            child: widget,
          );
  }
}
