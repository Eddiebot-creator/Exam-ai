import 'package:flutter/material.dart';
import '../theme/calm_theme.dart';
import 'app_entry.dart';

class ExamAIApp extends StatefulWidget {
  const ExamAIApp({super.key});
  @override
  State<ExamAIApp> createState() => _ExamAIAppState();
}

class _ExamAIAppState extends State<ExamAIApp> {
  ThemeMode mode = ThemeMode.light;
  void toggleTheme() => setState(() => mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExamAI',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: CalmTheme.light,
      darkTheme: CalmTheme.dark,
      home: AppEntry(onThemeToggle: toggleTheme, themeMode: mode),
    );
  }
}
