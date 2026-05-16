class AppConfig {
  static const String defaultApiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://exam-ai-113m.onrender.com',
  );
  static const String logo = 'assets/brand/examai_logo.png';
  static const String splash = 'assets/brand/examai_splash.png';
}
