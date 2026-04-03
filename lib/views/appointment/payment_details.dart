import 'package:flutter/material.dart';

Widget showPaymentStatus(BuildContext context, int status) {
  final IconData icon;
  final String label;
  final Color color;

  switch (status) {
    case 0:
      icon = Icons.schedule_rounded;
      label = 'Unpaid';
      color = const Color(0xFFDC2626);
      break;
    case 1:
      icon = Icons.check_circle_rounded;
      label = 'Paid';
      color = const Color(0xFF15803D);
      break;
    case 2:
      icon = Icons.cancel_rounded;
      label = 'Failed';
      color = const Color(0xFFDC2626);
      break;
    default:
      icon = Icons.help_outline_rounded;
      label = 'Unknown';
      color = Colors.grey;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withAlpha(60)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}
