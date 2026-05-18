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
  static const night = Color(0xff081411);
  static const nightPanel = Color(0xff132a25);
  static const nightPanelSoft = Color(0xff193832);
  static const glowTeal = Color(0xff21d7c4);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: teal, brightness: Brightness.light, surface: Colors.white);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme.copyWith(primary: teal, secondary: purple, tertiary: orange, surface: paper, surfaceContainerHighest: const Color(0xffe7f4ef)),
      scaffoldBackgroundColor: const Color(0xffeef7f3),
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
        fillColor: const Color(0xfff2faf7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: teal, width: 1.4)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: const Color(0xff16c7b7), foregroundColor: Colors.white)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: teal, side: BorderSide(color: teal.withOpacity(.28)))),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: paper,
        indicatorColor: teal.withOpacity(.12),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(seedColor: glowTeal, brightness: Brightness.dark, surface: nightPanel);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(primary: glowTeal, secondary: const Color(0xff8ea4ff), tertiary: const Color(0xffffb86b), surface: nightPanel, surfaceContainerHighest: nightPanelSoft),
      scaffoldBackgroundColor: night,
      fontFamily: 'Arial',
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      }),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xff0d211d),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(.08))),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: glowTeal, width: 1.4)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: glowTeal, foregroundColor: night, textStyle: const TextStyle(fontWeight: FontWeight.w900))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: glowTeal, side: BorderSide(color: glowTeal.withOpacity(.28)))),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xff0a1714),
        indicatorColor: glowTeal.withOpacity(.14),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
