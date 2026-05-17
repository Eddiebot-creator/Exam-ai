import 'package:flutter/material.dart';

class AppColors {
  static const teal = Color(0xff0f9f95);
  static const indigo = Color(0xff6366f1);
  static const gold = Color(0xffffb547);
  static const ink = Color(0xff172331);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.teal, brightness: Brightness.light),
    scaffoldBackgroundColor: const Color(0xfff7fbfa),
    fontFamily: 'Arial',
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.teal, brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xff07111d),
    fontFamily: 'Arial',
  );
}
