import 'package:flutter/material.dart';

class CalmTheme {
  static const teal = Color(0xff0f9f95);
  static const mint = Color(0xffdff8ef);
  static const cream = Color(0xfff7f3e8);
  static const ink = Color(0xff101923);
  static const softInk = Color(0xff5d6878);
  static const orange = Color(0xffe16f2d);
  static const gold = Color(0xffc99b22);
  static const purple = Color(0xff6d5bd0);
  static const blue = Color(0xff2563eb);
  static const indigo = Color(0xff4452c7);
  static const green = Color(0xff159947);
  static const rose = Color(0xffd84d67);
  static const graphite = Color(0xff202a35);
  static const paper = Color(0xfffbfcfa);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: teal, brightness: Brightness.light, surface: Colors.white);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme.copyWith(primary: teal, secondary: purple, tertiary: orange, surface: paper),
      scaffoldBackgroundColor: const Color(0xfff4f7f5),
      fontFamily: 'Arial',
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      }),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w900, color: ink),
        headlineMedium: TextStyle(fontWeight: FontWeight.w900, color: ink),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: ink),
        titleMedium: TextStyle(fontWeight: FontWeight.w800, color: ink),
        bodyLarge: TextStyle(color: ink),
        bodyMedium: TextStyle(color: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xfff2f7f6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: teal, width: 1.4)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: paper,
        indicatorColor: teal.withOpacity(.12),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(seedColor: teal, brightness: Brightness.dark, surface: const Color(0xff12202f));
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(primary: const Color(0xff35e0d1), secondary: const Color(0xffa78bfa), tertiary: orange, surface: const Color(0xff12202f)),
      scaffoldBackgroundColor: const Color(0xff07111d),
      fontFamily: 'Arial',
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      }),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xff35e0d1), width: 1.4)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xff0d1825),
        indicatorColor: const Color(0xff35e0d1).withOpacity(.14),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
