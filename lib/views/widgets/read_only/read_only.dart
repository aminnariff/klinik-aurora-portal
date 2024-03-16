import 'package:flutter/material.dart';

class ReadOnly extends StatelessWidget {
  final Widget widget;
  final bool isEditable;

  const ReadOnly(
    this.widget, {
    super.key,
    required this.isEditable,
  });

  @override
  Widget build(BuildContext context) {
    return isEditable
        ? widget
        : AbsorbPointer(
            child: widget,
          );
  }
}
