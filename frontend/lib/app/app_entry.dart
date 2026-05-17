import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/biometric_auth_service.dart';
import '../screens/auth/biometric_unlock_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/dashboard/calm_student_app.dart';
import '../screens/onboarding/smart_onboarding_screen.dart';
import '../utils/ui_helpers.dart';

class AppEntry extends StatefulWidget {
  const AppEntry({super.key, required this.onThemeToggle, required this.themeMode});
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;
  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool loading = true;
  Map<String, dynamic>? user;
  Map<String, dynamic>? lockedUser;
  late ApiClient api;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    api = ApiClient(prefs.getString('api_base') ?? AppConfig.defaultApiBase);
    final savedUser = prefs.getString('user');
    if (savedUser != null) {
      final parsed = jsonDecode(savedUser) as Map<String, dynamic>;
      final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      final deviceReady = await BiometricAuthService.isReady();
      if (biometricEnabled && deviceReady) { lockedUser = parsed; } else { user = parsed; }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _setUser(ApiClient nextApi, Map<String, dynamic> nextUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base', nextApi.baseUrl);
    await prefs.setString('user', jsonEncode(nextUser));
    setState(() { api = nextApi; user = nextUser; lockedUser = null; });
  }

  Future<void> _updateUser(Map<String, dynamic> nextUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(nextUser));
    if (mounted) setState(() => user = nextUser);
  }

  Future<void> _unlock() async {
    final ok = await BiometricAuthService.authenticate(reason: 'Unlock your ExamAI study space');
    if (!mounted) return;
    if (ok && lockedUser != null) { setState(() { user = lockedUser; lockedUser = null; }); } else { toast(context, 'Unlock cancelled.'); }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    setState(() { user = null; lockedUser = null; });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SplashScreen();
    if (lockedUser != null) return BiometricUnlockScreen(user: lockedUser!, onUnlock: _unlock, onUsePassword: () => setState(() => lockedUser = null), onThemeToggle: widget.onThemeToggle, themeMode: widget.themeMode);
    if (user == null) return LoginScreen(initialApi: api, onSuccess: _setUser, onThemeToggle: widget.onThemeToggle, themeMode: widget.themeMode);
    if ((user!['exam_course']?.toString().isEmpty ?? true) || (user!['exam_date']?.toString().isEmpty ?? true)) {
      return SmartOnboardingScreen(api: api, user: user!, onComplete: _updateUser, onLogout: _logout);
    }
    return CalmStudentApp(api: api, user: user!, onLogout: _logout, onThemeToggle: widget.onThemeToggle, themeMode: widget.themeMode, onUserChanged: _updateUser);
  }
}
