// fvm flutter pub run flutter_launcher_icons -f launcher_icons.yaml

import 'package:flutter/material.dart';

const primary = Color(0xFFDF6E98);
const primaryColors = [
  Color(0xFFDF6E98),
  // Color(0XFFD2ACB9),
  Color(0XFF6ad1e3),
];

const secondaryColor = Color(0xFF7e2d40);
const tertiaryColor = Color(0XFF07272d);
const quaternaryColor = Color(0XFF6ad1e3);

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
        return [
          const Color(0XFF23286C),
          const Color(0XFF52B3E0),
        ];
      }

    default:
      return [
        const Color(0XFF23286C),
        const Color(0XFF52B3E0),
      ];
  }
}

Color statusColor(status) {
  if (status.contains('ERROR')) {
    return const Color(0XFFDF184A);
  } else {
    switch (status) {
      case 'COMPLETE':
        return const Color(0XFF2ECC40);

      case 'ORDER_COMPLETE':
        return const Color(0XFF2ECC40);

      case 'SWAPPED':
        return Colors.green.shade900;

      case 'ACTIVE':
        return Colors.green.shade900;

      case 'ACTIVATED':
        return Colors.green.shade900;

      case 'RESOLVED':
        return Colors.green.shade900;

      case 'CANCELLED':
        return const Color(0XFFDF184A);

      case 'WARNING':
        return const Color(0XFFDF184A);

      case 'ERROR_CALLBACK':
        return const Color(0XFFDF184A);

      case 'FAILED':
        return const Color(0XFFDF184A);

      case 'TERMINATED':
        return const Color(0XFFDF184A);

      case 'NLT_DELAY':
        return const Color(0XFFDF184A);

      case 'TASK_RAISED':
        return const Color(0XFFDF184A);

      case 'PENDING_TERMINATION':
        return const Color(0xFFEDB81A);

      case 'CONFIRM':
        return const Color(0xFFEDB81A);

      case 'IN_PROGRESS':
        return const Color(0xFFEDB81A);

      case 'PENDING':
        return const Color(0xFFEDB81A);

      case 'RECONNECT':
        return const Color(0xFFFFC107);

      case 'PENDING_ACTIVE':
        return const Color(0xFF1C4B9D);

      case 'WAITING_CALL_BACK':
        return const Color(0xFF1C4B9D);

      case 'OPEN':
        return const Color(0xFF1C4B9D);

      case 'NEW':
        return const Color(0XFF0074D9);

      case 'true':
        return const Color(0XFF2ECC40);

      case 'false':
        return const Color(0XFFDF184A);

      default:
        return const Color(0XFF52B3E0);
    }
  }
}
