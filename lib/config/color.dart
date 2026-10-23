// fvm flutter pub run flutter_launcher_icons -f launcher_icons.yaml

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/gestational/gestational_controller.dart';

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

/// White — for text sitting on a **dark** surface, such as the sidebar.
///
/// Not the muted body colour: on a white card this is invisible. Use
/// [textMutedColor] for secondary text on light surfaces.
Color? textSecondaryColor = Colors.white;

/// Muted grey for secondary text on light surfaces (cards, dialogs, forms).
const textMutedColor = Color(0xFF637381);
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

List<Color> colorOptions(String color) {
  switch (color) {
    case 'primary':
      {
        return [const Color(0XFF23286C), const Color(0XFF52B3E0)];
      }

    default:
      return [const Color(0XFF23286C), const Color(0XFF52B3E0)];
  }
}

Color statusColor(String? status) {
  if (status?.contains('ERROR') == true) {
    return const Color(0xFFDC2626);
  } else {
    switch (status) {
      case 'active' || 'completed':
        return const Color(0xFF059669);

      case 'inactive':
        return const Color(0xFFDC2626);

      case 'in-progress':
        return const Color(0xFFD97706);

      case 'NEW':
        return const Color(0xFF2563EB);

      case '1' || 'true':
        return const Color(0xFF059669);

      case '0' || 'false':
        return const Color(0xFFDC2626);

      default:
        return const Color(0xFF0D9488);
    }
  }
}

final Map<int, Color> appointmentStatusColors = {
  1: const Color(0xFF2563EB), // Booked (blue-600)
  2: const Color(0xFFDC2626), // Cancelled (red-600)
  3: const Color(0xFFD97706), // Rescheduled (amber-600)
  4: const Color(0xFFB45309), // Pending Payment (amber-700)
  5: const Color(0xFF059669), // Completed (emerald-600)
  6: const Color(0xFF64748B), // Refunded (slate-500)
  7: const Color(0xFF7C3AED), // No Show (violet-600)
  8: const Color(0xFF0D9488), // Transferred (teal-600)
};

Color gestationalStatusColor(GestationalEligibility? eligiblity) {
  switch (eligiblity) {
    case GestationalEligibility.eligible:
      return const Color(0xFF29A838);

    case GestationalEligibility.tooFar:
      return const Color(0XFFDF184A);

    case GestationalEligibility.notYetEligible:
      return const Color.fromARGB(255, 209, 165, 35);

    default:
      return const Color(0xFF1C4B9D);
  }
}
