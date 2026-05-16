import 'package:flutter/material.dart';

class CalmTheme {
  static const teal = Color(0xff0f9f95);
  static const mint = Color(0xffe7fbf7);
  static const cream = Color(0xfffffbf4);
  static const ink = Color(0xff172331);
  static const softInk = Color(0xff627083);
  static const orange = Color(0xffff9f43);
  static const gold = Color(0xffffc857);
  static const purple = Color(0xff8b5cf6);
  static const blue = Color(0xff3b82f6);
  static const indigo = Color(0xff6366f1);
  static const green = Color(0xff22c55e);
  static const rose = Color(0xffff6b8a);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: teal, brightness: Brightness.light, surface: Colors.white);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme.copyWith(primary: teal, secondary: purple, tertiary: orange, surface: Colors.white),
      scaffoldBackgroundColor: const Color(0xfff7fbfa),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: teal, width: 1.4)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xff35e0d1), width: 1.4)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xff0d1825),
        indicatorColor: const Color(0xff35e0d1).withOpacity(.14),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
