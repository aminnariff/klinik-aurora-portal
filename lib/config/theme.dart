import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';

ThemeData theme(BuildContext context) {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: primary,
    primary: primary,
    secondary: secondaryColor,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: baseScheme.copyWith(
      surface: Colors.white,
      surfaceTint: Colors.transparent,
      outline: borderSubtle,
    ),
    brightness: Brightness.light,
    canvasColor: Colors.white,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    primaryColor: primary,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Figtree',
    dividerTheme: const DividerThemeData(color: borderSubtle, thickness: 1),
    dialogTheme: const DialogThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
    popupMenuTheme: const PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.transparent),
    cardTheme: const CardThemeData(color: Colors.white, surfaceTintColor: Colors.transparent),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: neutralDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      waitDuration: const Duration(milliseconds: 300),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryAccessibleText, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        padding: EdgeInsets.zero,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: textPrimaryColor),
      displayMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimaryColor),
      displaySmall: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: <Color>[Color(0XFFAD1F61), Color(0XFF46006A)],
          ).createShader(const Rect.fromLTWH(0.0, 0.0, 500.0, 70.0)),
      ),
      bodyLarge: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: textPrimaryColor),
      bodyMedium: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal, color: textPrimaryColor),
      titleLarge: const TextStyle(fontSize: 30, fontWeight: FontWeight.normal, color: textPrimaryColor),
      titleMedium: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.normal, color: textPrimaryColor),
      titleSmall: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600, color: textPrimaryColor),
      labelLarge: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: textPrimaryColor),
      bodySmall: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: textPrimaryColor),
    ),
  );
}

// Dark Them
ThemeData darkThemeData(BuildContext context) {
  return ThemeData.dark().copyWith(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF86337c),
    canvasColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardThemeData(
      color: const Color(0xFF141d26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    textTheme: TextTheme(
      displayLarge: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
      displayMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      displaySmall: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: <Color>[Color(0XFFAD1F61), Color(0XFF46006A)],
          ).createShader(const Rect.fromLTWH(0.0, 0.0, 500.0, 70.0)),
      ),
      bodyLarge: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
      bodyMedium: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal, color: Colors.white),
      titleLarge: const TextStyle(fontSize: 30, fontWeight: FontWeight.normal, color: Colors.white),
      titleMedium: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.normal, color: Colors.white),
      titleSmall: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600, color: Colors.white),
      labelLarge: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
      bodySmall: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Colors.white),
    ),
  );
}

AppBarTheme appBarTheme = const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0);
