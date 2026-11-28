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

// Live Theme-Aware Status Pill Text Colors (High-contrast, WCAG AA/AAA compliant)
Color get appDangerText => _activeIsDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
Color get appSuccessText => _activeIsDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D);
Color get appWarningText => _activeIsDark ? const Color(0xFFFDE047) : const Color(0xFFB45309);
Color get appInfoText => _activeIsDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
Color get appPurpleText => _activeIsDark ? const Color(0xFFD8B4FE) : const Color(0xFF6D28D9);
Color get appTealText => _activeIsDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
// Text on orange notice boxes (booking fee, cancellation policy).
Color get appOrangeText => _activeIsDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412);
// Violet chip text (e.g. "Pre-filled from Baby Tracker").
Color get appVioletText => _activeIsDark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED);
// Sky-blue link/button text.
Color get appSkyText => _activeIsDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1);
// Deep amber headings on warning boxes.
Color get appAmberText => _activeIsDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
// Deep green text on success boxes.
Color get appGreenText => _activeIsDark ? const Color(0xFF86EFAC) : const Color(0xFF166534);
Color get appLeafText => _activeIsDark ? const Color(0xFF6EE7B7) : const Color(0xFF1E822B);

// Live Theme-Aware Chart Tooltip Styling (Always dark high-contrast pill with crisp white text)
Color get appTooltipBg => _activeIsDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A);
Color get appTooltipText => const Color(0xFFF8FAFC);
Color get appTooltipBorder => _activeIsDark ? const Color(0xFF334155) : const Color(0xFF1E293B);

/// Automatically brightens saturated light-mode colors (e.g. dark green, dark blue, indigo, amber, red)
/// into high-contrast WCAG 4.5:1+ pastels in dark mode.
Color accessibleAccent(Color color) {
  if (!_activeIsDark) return color;
  // Greens
  if (color == const Color(0xFF16A34A) ||
      color == const Color(0xFF15803D) ||
      color == const Color(0xFF166534) ||
      color == const Color(0xFF065F46) ||
      color == const Color(0xFF047857) ||
      color == const Color(0xFF059669)) {
    return const Color(0xFF4ADE80);
  }
  // Blues
  if (color == const Color(0xFF2563EB) ||
      color == const Color(0xFF1D4ED8) ||
      color == const Color(0xFF1E40AF) ||
      color == const Color(0xFF1E3A8A)) {
    return const Color(0xFF60A5FA);
  }
  // Indigos / Purples
  if (color == const Color(0xFF4F46E5) ||
      color == const Color(0xFF6366F1) ||
      color == const Color(0xFF4338CA) ||
      color == const Color(0xFF3730A3) ||
      color == const Color(0xFF312E81)) {
    return const Color(0xFFA5B4FC);
  }
  // Sky / Cyans
  if (color == const Color(0xFF0284C7) ||
      color == const Color(0xFF0369A1) ||
      color == const Color(0xFF075985)) {
    return const Color(0xFF38BDF8);
  }
  // Teals
  if (color == const Color(0xFF0D9488) ||
      color == const Color(0xFF0F766E) ||
      color == const Color(0xFF115E59) ||
      color == const Color(0xFF134E4A)) {
    return const Color(0xFF2DD4BF);
  }
  // Ambers / Browns / Oranges
  if (color == const Color(0xFFD97706) ||
      color == const Color(0xFFB45309) ||
      color == const Color(0xFF92400E) ||
      color == const Color(0xFF9A3412) ||
      color == const Color(0xFFC2410C) ||
      color == const Color(0xFFEA580C) ||
      color == const Color(0xFFF59E0B)) {
    return const Color(0xFFFBBF24);
  }
  // Violets / Purples
  if (color == const Color(0xFF7C3AED) ||
      color == const Color(0xFF6D28D9) ||
      color == const Color(0xFF5B21B6)) {
    return const Color(0xFFA78BFA);
  }
  // Reds
  if (color == const Color(0xFFDC2626) ||
      color == const Color(0xFFB91C1C) ||
      color == const Color(0xFF991B1B) ||
      color == const Color(0xFF7F1D1D) ||
      color == const Color(0xFFEF4444)) {
    return const Color(0xFFF87171);
  }
  return color;
}

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
