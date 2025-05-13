import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/tooltip/app_tooltip.dart';

Widget showStatus(bool? value, {String? valueText, Color? valueColor}) {
  return AppTooltip(
    message: valueText ?? (value == true ? 'Active' : 'Inactive'),
    child: Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: valueColor ?? (value == true ? Colors.green : Colors.red),
        shape: BoxShape.circle,
      ),
    ),
  );
}
