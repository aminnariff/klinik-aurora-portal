import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
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

class AppointmentStatusBadge extends StatelessWidget {
  final int? status;
  final double fontSize;
  final EdgeInsets padding;
  final bool showDot;

  final bool isUppercase;

  const AppointmentStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.showDot = false,
    this.isUppercase = false,
  });

  @override
  Widget build(BuildContext context) {
    // fallback to grey/Unknown if status is not found or null
    final color = appointmentStatusColors[status] ?? Colors.grey;
    String label = getAppointmentStatusLabel(status);
    if (isUppercase) label = label.toUpperCase();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
