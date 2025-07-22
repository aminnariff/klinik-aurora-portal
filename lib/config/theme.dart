import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';

ThemeData theme(BuildContext context) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    brightness: Brightness.light,
    canvasColor: Colors.white,
    primaryColor: primary,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Proxima',
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
      bodyMedium: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: textPrimaryColor),
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
    // canvasColor: const Color(0xFF141d26),
    // scaffoldBackgroundColor: const Color(0xFF141d26),
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
      bodyMedium: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.white),
      titleLarge: const TextStyle(fontSize: 30, fontWeight: FontWeight.normal, color: Colors.white),
      titleMedium: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.normal, color: Colors.white),
      titleSmall: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600, color: Colors.white),
      labelLarge: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
      bodySmall: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Colors.white),
    ),
    // textTheme: GoogleFonts.latoTextTheme().copyWith(
    //   bodyText1: TextStyle(color: kBodyTextColorDark),
    //   bodyText2: TextStyle(color: kBodyTextColorDark),
    //   headline4: TextStyle(color: kTitleTextDarkColor, fontSize: 32),
    //   headline1: TextStyle(color: kTitleTextDarkColor, fontSize: 80),
    // ),
  );
}

AppBarTheme appBarTheme = const AppBarTheme(color: Colors.transparent, elevation: 0);
