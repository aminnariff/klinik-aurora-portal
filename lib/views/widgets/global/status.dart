import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/tooltip/app_tooltip.dart';

Widget showStatus(bool? value, {String? valueText, Color? valueColor}) {
  final color = valueColor ?? (value == true ? const Color(0xFF059669) : const Color(0xFFDC2626));
  final label = valueText ?? (value == true ? 'Active' : 'Inactive');

  return AppTooltip(
    message: label,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    this.showDot = true,
    this.isUppercase = false,
  });

  @override
  Widget build(BuildContext context) {
    // fallback to grey/Unknown if status is not found or null
    final color = appointmentStatusColors[status] ?? const Color(0xFF64748B);
    String label = getAppointmentStatusLabel(status);
    if (isUppercase) label = label.toUpperCase();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
