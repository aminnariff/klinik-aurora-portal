// fvm flutter pub run flutter_launcher_icons -f launcher_icons.yaml

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/app_theme_preset.dart';
import 'package:klinik_aurora_portal/controllers/gestational/gestational_controller.dart';

// ── Active Brand Theme (synced by DarkModeController / ThemeController) ──────
AuroraThemePreset _activePreset = AuroraThemePreset.auroraPlum;
bool _activeIsDark = false;

/// Updates the active brand preset & brightness so legacy top-level getters
/// ([primary], [primaryButtonColor], [primaryAccessibleText], [primaryColors])
/// reflect live user theme customization across all screens.
void syncActiveBrandTheme({required AuroraThemePreset preset, required bool isDark}) {
  _activePreset = preset;
  _activeIsDark = isDark;
}

const brandPink = Color(0xFFDF6E98);
const defaultAuroraPlum = Color(0xFF7E2D40);

/// Active primary brand color (defaults to Klinik Aurora Plum #7E2D40;
/// customizable in Appearance & Theme settings).
Color get primary => _activeIsDark ? _activePreset.primaryDark : _activePreset.primaryLight;
Color get primaryButtonColor => primary;
List<Color> get primaryColors =>
    _activePreset.gradientFor(_activeIsDark ? Brightness.dark : Brightness.light);

const secondaryColor = Color(0xFF6AD1E3);
const tertiaryColor = Color(0xFF07272D);
const quaternaryColor = Color(0xFF7E2D40);
const sidebarColor = Color(0xFF1B545E);

// WCAG AA/AAA Compliant accessible variants for text/icons (>4.5:1 contrast)
Color get primaryAccessibleText =>
    _activeIsDark ? _activePreset.accessibleTextDark : _activePreset.accessibleTextLight;
Color get secondaryAccessibleText =>
    _activeIsDark ? const Color(0xFF6AD1E3) : const Color(0xFF007A93);

// Live Theme-Aware Semantic Surface, Border & Ink Tokens (Light & Dark Mode)
bool get appIsDarkMode => _activeIsDark;
Color get appCanvas => _activeIsDark ? const Color(0xFF0B1217) : const Color(0xFFF6F8FA);
Color get appSurface => _activeIsDark ? const Color(0xFF111B22) : const Color(0xFFFFFFFF);
Color get appSurfaceSubtle => _activeIsDark ? const Color(0xFF17242D) : const Color(0xFFF1F5F9);
Color get appSurfaceElevated => _activeIsDark ? const Color(0xFF1C2B36) : const Color(0xFFFFFFFF);
Color get appTableHeaderBg => _activeIsDark ? const Color(0xFF15212B) : const Color(0xFFF8FAFC);
Color get appTableRowAlt => _activeIsDark ? const Color(0xFF142029) : const Color(0xFFFAFAFC);
Color get appInputFill => _activeIsDark ? const Color(0xFF0E171E) : const Color(0xFFFFFFFF);
Color get appBorder => _activeIsDark ? const Color(0xFF243644) : const Color(0xFFE2E8F0);
Color get appBorderStrong => _activeIsDark ? const Color(0xFF334B5E) : const Color(0xFFCBD5E1);
Color get appInkPrimary => _activeIsDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
Color get appInkSecondary => _activeIsDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
Color get appInkMuted => _activeIsDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

// Live Theme-Aware Status Pill Soft Backgrounds (Light pastel / Dark deep tint)
Color get appDangerSoft => _activeIsDark ? const Color(0xFF3B1519) : const Color(0xFFFEF2F2);
Color get appSuccessSoft => _activeIsDark ? const Color(0xFF0E2F26) : const Color(0xFFECFDF5);
Color get appWarningSoft => _activeIsDark ? const Color(0xFF35260C) : const Color(0xFFFFFBEB);
Color get appInfoSoft => _activeIsDark ? const Color(0xFF0E2738) : const Color(0xFFEFF6FF);
Color get appPurpleSoft => _activeIsDark ? const Color(0xFF271B3D) : const Color(0xFFF5F3FF);
Color get appTealSoft => _activeIsDark ? const Color(0xFF0E2E30) : const Color(0xFFF0FDFA);

Color get neutralDark => appInkPrimary;
Color get neutralMuted => appInkMuted;
Color get borderSubtle => appBorder;
Color get surfaceLight => appCanvas;

// TextFormField
Color get textFormFieldEditableColor =>
    _activeIsDark ? const Color(0xFF0E171E) : const Color(0xFFF8FAFC);
Color get textFormFieldUneditableColor =>
    _activeIsDark ? const Color(0xFF17242D) : const Color(0xFFF1F5F9);

// Button
Color get disabledColor =>
    _activeIsDark ? const Color(0xFF1F2D38) : const Color(0xFFEAEAEA);

// Shimmer
Color get shimmerBaseColor =>
    _activeIsDark ? const Color(0xFF1A2833) : const Color(0xFFEEEDED);
Color get shimmerHighlightColor =>
    _activeIsDark ? const Color(0xFF263A48) : Colors.white;

// Card
Color get cardColor => appSurfaceSubtle;
const darkModeCardColor = Color(0xFF111B22);
Color get shadow =>
    _activeIsDark ? const Color(0x44000000) : const Color(0x180F172A);

// Error
Color get errorColor =>
    _activeIsDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);

// Text
Color get textPrimaryColor => appInkPrimary;

/// White — for text sitting on a **dark** surface, such as the sidebar.
///
/// Not the muted body colour: on a white card this is invisible. Use
/// [textMutedColor] for secondary text on light surfaces.
Color? textSecondaryColor = Colors.white;

/// Muted grey for secondary text on surfaces (cards, dialogs, forms).
Color get textMutedColor => appInkMuted;
Color get textTertiaryColor =>
    _activeIsDark ? const Color(0xFF60A5FA) : const Color(0xFF1C61AC);
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
      return primaryColors;
    default:
      return [const Color(0xFF246E7A), const Color(0xFF1B545E)];
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
      return const Color(0xFF059669);

    case GestationalEligibility.tooFar:
      return const Color(0xFFDC2626);

    case GestationalEligibility.notYetEligible:
      return const Color(0xFFB45309);

    default:
      return const Color(0xFF1C4B9D);
  }
}
