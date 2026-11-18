import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/app_theme_preset.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';

/// Builds the Light [ThemeData] for Klinik Aurora Portal using [preset].
ThemeData buildLightTheme(
  BuildContext context, [
  AuroraThemePreset preset = AuroraThemePreset.auroraPlum,
  TableDensity density = TableDensity.comfortable,
]) {
  final tokens = AppColors.light(preset);
  final baseScheme = ColorScheme.fromSeed(
    seedColor: tokens.brandPrimary,
    brightness: Brightness.light,
    primary: tokens.brandPrimary,
    onPrimary: tokens.brandOnPrimary,
    secondary: secondaryColor,
    surface: tokens.surface,
    error: tokens.danger,
  );

  return _buildBaseTheme(
    brightness: Brightness.light,
    colorScheme: baseScheme.copyWith(
      primary: tokens.brandPrimary,
      onPrimary: tokens.brandOnPrimary,
      surface: tokens.surface,
      onSurface: tokens.inkPrimary,
      onSurfaceVariant: tokens.inkMuted,
      surfaceContainerLowest: tokens.surface,
      surfaceContainerLow: tokens.surfaceSubtle,
      surfaceContainer: tokens.surfaceSubtle,
      surfaceContainerHigh: tokens.surfaceElevated,
      surfaceTint: Colors.transparent,
      outline: tokens.border,
      outlineVariant: tokens.border,
      error: tokens.danger,
    ),
    tokens: tokens,
    density: density,
  );
}

/// Builds the Dark [ThemeData] for Klinik Aurora Portal using [preset].
ThemeData buildDarkTheme(
  BuildContext context, [
  AuroraThemePreset preset = AuroraThemePreset.auroraPlum,
  TableDensity density = TableDensity.comfortable,
]) {
  final tokens = AppColors.dark(preset);
  final baseScheme = ColorScheme.fromSeed(
    seedColor: tokens.brandPrimary,
    brightness: Brightness.dark,
    primary: tokens.brandPrimary,
    onPrimary: tokens.brandOnPrimary,
    secondary: secondaryColor,
    surface: tokens.surface,
    error: tokens.danger,
  );

  return _buildBaseTheme(
    brightness: Brightness.dark,
    colorScheme: baseScheme.copyWith(
      primary: tokens.brandPrimary,
      onPrimary: tokens.brandOnPrimary,
      surface: tokens.surface,
      onSurface: tokens.inkPrimary,
      onSurfaceVariant: tokens.inkMuted,
      surfaceContainerLowest: tokens.canvas,
      surfaceContainerLow: tokens.surface,
      surfaceContainer: tokens.surfaceSubtle,
      surfaceContainerHigh: tokens.surfaceElevated,
      surfaceTint: Colors.transparent,
      outline: tokens.border,
      outlineVariant: tokens.border,
      error: tokens.danger,
    ),
    tokens: tokens,
    density: density,
  );
}

ThemeData _buildBaseTheme({
  required Brightness brightness,
  required ColorScheme colorScheme,
  required AppColors tokens,
  required TableDensity density,
}) {
  final isDark = brightness == Brightness.dark;
  final isCompact = density == TableDensity.compact;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    extensions: <ThemeExtension<dynamic>>[tokens],
    canvasColor: tokens.surface,
    scaffoldBackgroundColor: tokens.canvas,
    cardColor: tokens.surface,
    primaryColor: tokens.brandPrimary,
    focusColor: tokens.brandPrimary.withValues(alpha: 0.14),
    hoverColor: tokens.tableRowHover,
    splashColor: tokens.brandPrimary.withValues(alpha: 0.10),
    highlightColor: tokens.brandPrimary.withValues(alpha: 0.06),
    visualDensity: isCompact ? const VisualDensity(horizontal: -2, vertical: -2) : VisualDensity.adaptivePlatformDensity,
    listTileTheme: ListTileThemeData(
      dense: isCompact,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10.0 : 16.0,
        vertical: isCompact ? 0.0 : 4.0,
      ),
      minVerticalPadding: isCompact ? 4.0 : 10.0,
    ),
    fontFamily: 'Figtree',
    iconTheme: IconThemeData(color: tokens.inkSecondary),
    dividerTheme: DividerThemeData(color: tokens.border, thickness: 1, space: 1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: tokens.brandText,
      selectionColor: tokens.brandPrimary.withValues(alpha: isDark ? 0.35 : 0.20),
      selectionHandleColor: tokens.brandPrimary,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: WidgetStateProperty.all(false),
      thickness: WidgetStateProperty.all(6),
      radius: const Radius.circular(8),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.dragged)) {
          return tokens.inkMuted.withValues(alpha: 0.65);
        }
        return tokens.inkMuted.withValues(alpha: 0.35);
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: TextStyle(
        fontFamily: 'Figtree',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: tokens.inkPrimary,
      ),
      contentTextStyle: TextStyle(
        fontFamily: 'Figtree',
        fontSize: 14,
        color: tokens.inkSecondary,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: tokens.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: tokens.border),
      ),
      textStyle: TextStyle(
        fontFamily: 'Figtree',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: tokens.inkPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: tokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.all(isCompact ? 4.0 : 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tokens.border),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowHeight: isCompact ? 38 : 46,
      dataRowMinHeight: isCompact ? 40 : 48,
      dataRowMaxHeight: isCompact ? 50 : 60,
      columnSpacing: isCompact ? 12 : 20,
      headingRowColor: WidgetStateProperty.all(tokens.tableHeaderBg),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return tokens.brandSoftBg;
        if (states.contains(WidgetState.hovered)) return tokens.tableRowHover;
        return tokens.surface;
      }),
      headingTextStyle: TextStyle(
        fontFamily: 'Figtree',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: tokens.inkSecondary,
      ),
      dataTextStyle: TextStyle(
        fontFamily: 'Figtree',
        fontSize: 13,
        color: tokens.inkPrimary,
      ),
      dividerThickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: tokens.surfaceSubtle,
      selectedColor: tokens.brandSoftBg,
      labelStyle: TextStyle(
        fontFamily: 'Figtree',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: tokens.inkPrimary,
      ),
      side: BorderSide(color: tokens.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return isDark ? tokens.inkMuted : Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return tokens.brandPrimary;
        return tokens.borderStrong;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return tokens.brandPrimary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: tokens.borderStrong, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: tokens.brandText,
      unselectedLabelColor: tokens.inkMuted,
      indicatorColor: tokens.brandPrimary,
      dividerColor: tokens.border,
      labelStyle: const TextStyle(fontFamily: 'Figtree', fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontFamily: 'Figtree', fontSize: 13, fontWeight: FontWeight.w500),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF060B0E) : const Color(0xFF0F172A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        border: isDark ? Border.all(color: tokens.border) : null,
      ),
      textStyle: const TextStyle(fontFamily: 'Figtree', color: Colors.white, fontSize: 12),
      waitDuration: const Duration(milliseconds: 300),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.inputFill,
      isDense: isCompact,
      hintStyle: TextStyle(color: tokens.inkMuted, fontSize: isCompact ? 12 : 13),
      labelStyle: TextStyle(color: tokens.inkSecondary, fontSize: isCompact ? 12 : 13, fontWeight: FontWeight.w600),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 11 : 14,
        vertical: isCompact ? 9 : 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.brandText, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.danger, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.brandPrimary,
        foregroundColor: tokens.brandOnPrimary,
        textStyle: TextStyle(fontFamily: 'Figtree', fontWeight: FontWeight.w600, fontSize: isCompact ? 12 : 13),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: isCompact ? 6 : 10),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.inkSecondary,
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: isCompact ? 6 : 10),
        side: BorderSide(color: tokens.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.brandPrimary,
        foregroundColor: tokens.brandOnPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.brandText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: tokens.inkPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: tokens.inkPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: tokens.brandText,
      ),
      bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: tokens.inkPrimary),
      bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400, color: tokens.inkPrimary),
      titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: tokens.inkPrimary),
      titleMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: tokens.inkPrimary),
      titleSmall: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600, color: tokens.inkPrimary),
      labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700, color: tokens.inkPrimary),
      bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400, color: tokens.inkMuted),
    ),
  );
}

/// Legacy compatibility helpers.
ThemeData theme(BuildContext context) => buildLightTheme(context);

ThemeData darkThemeData(BuildContext context) => buildDarkTheme(context);

AppBarTheme appBarTheme = const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0);
