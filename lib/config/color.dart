// fvm flutter pub run flutter_launcher_icons -f launcher_icons.yaml

import 'package:flutter/material.dart';

const primary = Color(0xFFDF6E98);
const primaryColors = [
  Color(0xFFDF6E98),
  // Color(0XFFD2ACB9),
  Color(0XFF6ad1e3),
];

const secondaryColor = Color(0XFF6ad1e3);
const tertiaryColor = Color(0XFF07272d);
const quaternaryColor = Color(0xFF7e2d40);
const sidebarColor = Color(0xFF52AFBF);

//TextFormField
const textFormFieldEditableColor = Color(0XFFF8F8F8);
const textFormFieldUneditableColor = Color(0xFFEEEEEE);

// Button
const Color disabledColor = Color(0XFFEAEAEA);

//Shimmer
const shimmerBaseColor = Color(0xFFEEEDED);
const shimmerHighlightColor = Colors.white;

//Card
const cardColor = Color(0XFFf4f5fa);
const darkModeCardColor = Color(0xFF141d26);
const shadow = Color(0XFFc2ddf0);

// Error
const Color errorColor = Color(0XFFDF184A);

//Text
const textPrimaryColor = Colors.black;
Color? textSecondaryColor = Colors.white;
const textTertiaryColor = Color(0XFF1C61AC);
const Color contentColorBlack = Colors.black;
const Color contentColorWhite = Colors.white;
const Color contentColorBlue = Color(0xFF2196F3);
const Color contentColorYellow = Color(0xFFFFC300);
const Color contentColorOrange = Color(0xFFFF683B);
const Color contentColorGreen = Color(0xFF2ECC40);
const Color contentColorPurple = Color(0xFF6E1BFF);
const Color contentColorPink = Color(0xFFFF3AF2);
const Color contentColorRed = Color(0xFFE80054);
const Color contentColorCyan = Color(0xFF50E4FF);

List<Color> colorOptions(color) {
  switch (color) {
    case 'primary':
      {
        return [const Color(0XFF23286C), const Color(0XFF52B3E0)];
      }

    default:
      return [const Color(0XFF23286C), const Color(0XFF52B3E0)];
  }
}

Color statusColor(status) {
  if (status.contains('ERROR')) {
    return const Color(0XFFDF184A);
  } else {
    switch (status) {
      case 'active' || 'completed':
        return Colors.green.shade900;

      case 'inactive':
        return const Color(0XFFDF184A);

      case 'in-progress':
        return const Color(0xFFFFC107);

      case 'NEW':
        return const Color(0XFF0074D9);

      case '1':
        return const Color(0XFF2ECC40);

      case 'true':
        return const Color(0XFF2ECC40);

      case 'false':
        return const Color(0XFFDF184A);

      case '0':
        return const Color(0XFFDF184A);

      default:
        return const Color(0XFF52B3E0);
    }
  }
}

final Map<int, Color> appointmentStatusColors = {
  1: Colors.blue, // Booked
  2: Colors.red, // Cancelled
  3: Colors.orange, // Rescheduled
  4: const Color(0xFFCD9B05), // Pending Payment
  5: Colors.green, // Completed
  6: Colors.grey, // Refunded
  7: Colors.purple, // No Show
};
