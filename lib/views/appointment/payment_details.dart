import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

Widget showPaymentStatus(BuildContext context, int status) {
  IconData icon;
  String label;
  Color color;

  switch (status) {
    case 0:
      icon = Icons.info;
      label = 'Unpaid';
      color = Colors.red.shade700;
      break;
    case 1:
      icon = Icons.check_circle;
      label = 'Paid';
      color = Colors.green;
      break;
    case 2:
      icon = Icons.cancel;
      label = 'Failed';
      color = Colors.red.shade700;
      break;
    default:
      icon = Icons.help_outline;
      label = 'Unknown';
      color = Colors.grey;
  }

  return Row(
    children: [
      Icon(icon, color: color),
      const SizedBox(width: 8),
      Text(label, style: AppTypography.bodyMedium(context).apply()),
    ],
  );
}
