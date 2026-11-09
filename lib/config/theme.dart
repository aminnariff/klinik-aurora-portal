import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';

ThemeData theme(BuildContext context) {
  final baseScheme = ColorScheme.fromSeed(seedColor: primary);
  return ThemeData(
    useMaterial3: true,
    colorScheme: baseScheme.copyWith(surface: Colors.white, surfaceTint: Colors.transparent),
    brightness: Brightness.light,
    canvasColor: Colors.white,
    primaryColor: primary,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Figtree',
    dialogTheme: const DialogThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
    popupMenuTheme: const PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.transparent),
    cardTheme: const CardThemeData(color: Colors.white, surfaceTintColor: Colors.transparent),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(color: Colors.white),
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

// Dark Theme
ThemeData darkThemeData(BuildContext context) {
  const darkBg = Color(0xFF0F172A);
  const darkSurface = Color(0xFF1E293B);
  final baseScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.dark,
  );
  return ThemeData.dark().copyWith(
    brightness: Brightness.dark,
    colorScheme: baseScheme.copyWith(
      surface: darkSurface,
      surfaceTint: Colors.transparent,
    ),
    primaryColor: const Color(0xFF86337c),
    canvasColor: darkBg,
    scaffoldBackgroundColor: darkBg,
    dialogTheme: const DialogThemeData(
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: darkSurface,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      bodySmall: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Color(0xFF94A3B8)),
    ),
  );
}

AppBarTheme appBarTheme = const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0);
