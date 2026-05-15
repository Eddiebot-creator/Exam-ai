import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kDefaultApiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://exam-ai-113m.onrender.com',
);
const String kLogo = 'assets/brand/examai_logo.png';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExamAIApp());
}

class ExamAIApp extends StatefulWidget {
  const ExamAIApp({super.key});

  @override
  State<ExamAIApp> createState() => _ExamAIAppState();
}

class _ExamAIAppState extends State<ExamAIApp> {
  ThemeMode mode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

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

class CalmTheme {
  static const teal = Color(0xff0f9f95);
  static const mint = Color(0xffe7fbf7);
  static const cream = Color(0xfffffbf4);
  static const ink = Color(0xff172331);
  static const softInk = Color(0xff627083);
  static const orange = Color(0xffff9f43);
  static const purple = Color(0xff8b5cf6);
  static const blue = Color(0xff3b82f6);
  static const indigo = Color(0xff6366f1);
  static const green = Color(0xff22c55e);
  static const rose = Color(0xffff6b8a);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme.copyWith(
        primary: teal,
        secondary: purple,
        tertiary: orange,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xfff7fbfa),
      fontFamily: 'Arial',
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: teal, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: teal.withOpacity(.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.dark,
      surface: const Color(0xff12202f),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: const Color(0xff35e0d1),
        secondary: const Color(0xffa78bfa),
        tertiary: orange,
        surface: const Color(0xff12202f),
      ),
      scaffoldBackgroundColor: const Color(0xff07111d),
      fontFamily: 'Arial',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xff35e0d1), width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xff0d1825),
        indicatorColor: const Color(0xff35e0d1).withOpacity(.14),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class ApiClient {
  ApiClient(this.baseUrl);
  final String baseUrl;

  Future<bool> ping() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/')).timeout(const Duration(seconds: 12));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 35));
    return _map(response);
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'full_name': name.trim(), 'email': email.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 35));
    return _map(response);
  }

  Future<List<dynamic>> notes(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/notes?user_id=$userId')).timeout(const Duration(seconds: 25));
    return _list(response);
  }

  Future<List<dynamic>> history(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/quiz/history?user_id=$userId')).timeout(const Duration(seconds: 25));
    return _list(response);
  }

  Future<Map<String, dynamic>> progress(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/progress/$userId')).timeout(const Duration(seconds: 25));
    return _map(response);
  }

  Future<Map<String, dynamic>> createTextNote(int userId, String title, String text) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/notes/text'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'title': title, 'text': text}),
        )
        .timeout(const Duration(seconds: 40));
    return _map(response);
  }

  Future<Map<String, dynamic>> uploadFile(int userId, String title, PlatformFile file) async {
    if (file.path == null) throw Exception('File path not available.');
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/notes/upload'));
    request.fields['user_id'] = '$userId';
    request.fields['title'] = title;
    request.files.add(await http.MultipartFile.fromPath('file', file.path!));
    final streamed = await request.send().timeout(const Duration(seconds: 70));
    return _map(http.Response(await streamed.stream.bytesToString(), streamed.statusCode));
  }

  Future<Map<String, dynamic>> aiChat(int userId, int? noteId, String message) async {
    final path = noteId == null ? '/pro/ai-tutor' : '/ai/chat-with-note/$noteId';
    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'note_id': noteId, 'message': message}),
        )
        .timeout(const Duration(seconds: 60));
    return _map(response);
  }


  Future<Map<String, dynamic>> recordStudyTime(int userId, int? noteId, String activity, int seconds) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/progress/study-time'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'note_id': noteId,
            'activity': activity,
            'seconds': seconds,
          }),
        )
        .timeout(const Duration(seconds: 25));
    return _map(response);
  }

  Future<Map<String, dynamic>> engineDashboard(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/engine/dashboard/$userId')).timeout(const Duration(seconds: 25));
    return _map(response);
  }


  Future<Map<String, dynamic>> updateProfile(
    int userId, {
    String? fullName,
    String? email,
    String? avatarCharacter,
    String? bio,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/auth/profile/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            if (fullName != null) 'full_name': fullName.trim(),
            if (email != null) 'email': email.trim(),
            if (avatarCharacter != null) 'avatar_character': avatarCharacter,
            if (bio != null) 'bio': bio.trim(),
          }),
        )
        .timeout(const Duration(seconds: 30));
    return _map(response);
  }

  Future<Map<String, dynamic>> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/auth/password/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 30));
    return _map(response);
  }

  Future<Map<String, dynamic>> uploadProfilePicture(int userId, PlatformFile file) async {
    if (file.path == null) throw Exception('File path not available.');
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/auth/profile-picture/$userId'));
    request.files.add(await http.MultipartFile.fromPath('file', file.path!));
    final streamed = await request.send().timeout(const Duration(seconds: 60));
    return _map(http.Response(await streamed.stream.bytesToString(), streamed.statusCode));
  }

  Map<String, dynamic> _map(http.Response response) {
    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(body['detail']?.toString() ?? 'Request failed (${response.statusCode}).');
    }
    return body;
  }

  List<dynamic> _list(http.Response response) {
    if (response.statusCode >= 400) throw Exception('Request failed (${response.statusCode}).');
    return response.body.isEmpty ? [] : jsonDecode(response.body) as List<dynamic>;
  }
}


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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    api = ApiClient(prefs.getString('api_base') ?? kDefaultApiBase);
    final savedUser = prefs.getString('user');
    if (savedUser != null) {
      final parsedUser = jsonDecode(savedUser) as Map<String, dynamic>;
      final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      final deviceReady = await BiometricAuthService.isReady();
      if (biometricEnabled && deviceReady) {
        lockedUser = parsedUser;
      } else {
        user = parsedUser;
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _setUser(ApiClient nextApi, Map<String, dynamic> nextUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base', nextApi.baseUrl);
    await prefs.setString('user', jsonEncode(nextUser));
    setState(() {
      api = nextApi;
      user = nextUser;
      lockedUser = null;
    });
  }

  Future<void> _updateUser(Map<String, dynamic> nextUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(nextUser));
    if (!mounted) return;
    setState(() => user = nextUser);
  }

  Future<void> _unlock() async {
    final ok = await BiometricAuthService.authenticate(
      reason: 'Unlock your ExamAI study space',
    );
    if (!mounted) return;
    if (ok && lockedUser != null) {
      setState(() {
        user = lockedUser;
        lockedUser = null;
      });
    } else {
      toast(context, 'Unlock cancelled.');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    setState(() {
      user = null;
      lockedUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SplashScreen();
    if (lockedUser != null) {
      return BiometricUnlockScreen(
        user: lockedUser!,
        onUnlock: _unlock,
        onUsePassword: () => setState(() => lockedUser = null),
        onThemeToggle: widget.onThemeToggle,
        themeMode: widget.themeMode,
      );
    }
    if (user == null) {
      return BeautifulLoginScreen(
        initialApi: api,
        onSuccess: _setUser,
        onThemeToggle: widget.onThemeToggle,
        themeMode: widget.themeMode,
      );
    }
    return CalmStudentApp(
      api: api,
      user: user!,
      onLogout: _logout,
      onThemeToggle: widget.onThemeToggle,
      themeMode: widget.themeMode,
      onUserChanged: _updateUser,
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CalmBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StudentMascot(size: 150, mood: MascotMood.happy),
              const SizedBox(height: 18),
              Text('ExamAI', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const SoftText('Your calm AI study coach'),
            ],
          ),
        ),
      ),
    );
  }
}


class BiometricUnlockScreen extends StatelessWidget {
  const BiometricUnlockScreen({
    super.key,
    required this.user,
    required this.onUnlock,
    required this.onUsePassword,
    required this.onThemeToggle,
    required this.themeMode,
  });

  final Map<String, dynamic> user;
  final VoidCallback onUnlock;
  final VoidCallback onUsePassword;
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final firstName = user['full_name']?.toString().split(' ').first ?? 'Scholar';
    return Scaffold(
      body: CalmBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SoftCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StudentMascot(size: 130, mood: MascotMood.wave),
                      const SizedBox(height: 18),
                      Text('Welcome back, $firstName', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const SoftText('Use your device security to reopen your calm study space.'),
                      const SizedBox(height: 22),
                      PrimaryCalmButton(
                        label: 'Unlock with device security',
                        icon: Icons.fingerprint_rounded,
                        onTap: onUnlock,
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: onUsePassword,
                        icon: const Icon(Icons.password_rounded),
                        label: const Text('Use email and password instead'),
                      ),
                      const SizedBox(height: 6),
                      IconButton.filledTonal(
                        tooltip: 'Light / dark mode',
                        onPressed: onThemeToggle,
                        icon: Icon(themeMode == ThemeMode.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BeautifulLoginScreen extends StatefulWidget {
  const BeautifulLoginScreen({
    super.key,
    required this.initialApi,
    required this.onSuccess,
    required this.onThemeToggle,
    required this.themeMode,
  });

  final ApiClient initialApi;
  final Future<void> Function(ApiClient api, Map<String, dynamic> user) onSuccess;
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;

  @override
  State<BeautifulLoginScreen> createState() => _BeautifulLoginScreenState();
}

class _BeautifulLoginScreenState extends State<BeautifulLoginScreen> {
  final name = TextEditingController(text: 'Demo Student');
  final email = TextEditingController(text: 'student@example.com');
  final password = TextEditingController(text: 'password123');
  final apiText = TextEditingController();
  bool signup = false;
  bool showApi = false;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    apiText.text = widget.initialApi.baseUrl;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: CalmBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: wide
                    ? Row(
                        children: [
                          const Expanded(flex: 6, child: LoginStoryPanel()),
                          const SizedBox(width: 28),
                          Expanded(flex: 4, child: _formCard()),
                        ],
                      )
                    : Column(
                        children: [
                          const LoginStoryPanel(compact: true),
                          const SizedBox(height: 20),
                          _formCard(),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard() {
    return SoftCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  signup ? 'Create your calm study space' : 'Welcome back',
                  style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Light / dark mode',
                onPressed: widget.onThemeToggle,
                icon: Icon(widget.themeMode == ThemeMode.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Backend settings',
                onPressed: () => setState(() => showApi = !showApi),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SoftText('No pressure. One step at a time.'),
          const SizedBox(height: 18),
          if (error != null) ErrorPanel(message: error!),
          if (showApi) ...[
            TextField(controller: apiText, decoration: const InputDecoration(labelText: 'Backend API URL', prefixIcon: Icon(Icons.cloud_queue_rounded))),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: busy ? null : _testApi, icon: const Icon(Icons.wifi_tethering_rounded), label: const Text('Test backend')),
            const SizedBox(height: 12),
          ],
          if (signup) ...[
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.badge_rounded))),
            const SizedBox(height: 12),
          ],
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded))),
          const SizedBox(height: 18),
          PrimaryCalmButton(
            label: busy ? 'Working...' : signup ? 'Create account' : 'Login',
            icon: signup ? Icons.person_add_rounded : Icons.login_rounded,
            onTap: busy ? null : _submit,
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: busy ? null : () => setState(() => signup = !signup), child: Text(signup ? 'I already have an account' : 'Create a new account')),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Demo: student@example.com / password123',
              style: TextStyle(color: muted(context), fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _apiBase() {
    var value = apiText.text.trim().isEmpty ? kDefaultApiBase : apiText.text.trim();
    if (!value.startsWith('http')) value = 'https://$value';
    if (value.endsWith('/')) value = value.substring(0, value.length - 1);
    return value;
  }

  Future<void> _testApi() async {
    setState(() {
      busy = true;
      error = null;
    });
    final ok = await ApiClient(_apiBase()).ping();
    if (!mounted) return;
    setState(() {
      busy = false;
      error = ok ? null : 'Backend did not respond. Check your Render URL.';
    });
    if (ok) toast(context, 'Backend connected.');
  }

  Future<void> _submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    final api = ApiClient(_apiBase());
    try {
      final nextUser = signup ? await api.register(name.text, email.text, password.text) : await api.login(email.text, password.text);
      await widget.onSuccess(api, nextUser);
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class LoginStoryPanel extends StatelessWidget {
  const LoginStoryPanel({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.all(compact ? 22 : 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StudentMascot(size: 116, mood: MascotMood.wave),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ExamAI', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    const SoftText('A friendly study coach for every student.'),
                  ],
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 30),
            const Text(
              'Study with less stress and more direction.',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, height: 1.05),
            ),
            const SizedBox(height: 16),
            const SoftText(
              'ExamAI guides your day, explains difficult topics, tracks weak areas, and keeps advanced tools tucked away until you need them.',
              size: 17,
            ),
            const SizedBox(height: 24),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                CalmPill(icon: Icons.psychology_rounded, label: 'AI study brain'),
                CalmPill(icon: Icons.checklist_rounded, label: 'Daily flow'),
                CalmPill(icon: Icons.style_rounded, label: 'Flashcards'),
                CalmPill(icon: Icons.auto_awesome_rounded, label: 'Gentle design'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum MascotMood { happy, wave, focus }

class StudentMascot extends StatelessWidget {
  const StudentMascot({super.key, this.size = 120, this.mood = MascotMood.happy});
  final double size;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final face = dark ? const Color(0xffbff8ee) : const Color(0xff9deee0);
    final outline = dark ? Colors.white.withOpacity(.12) : const Color(0xff0f766e).withOpacity(.16);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 850),
      tween: Tween(begin: .96, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: size * .05,
              child: Container(
                width: size * .82,
                height: size * .20,
                decoration: BoxDecoration(
                  color: CalmTheme.teal.withOpacity(.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Positioned(
              bottom: size * .16,
              child: Container(
                width: size * .58,
                height: size * .42,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xff1d3042) : Colors.white,
                  borderRadius: BorderRadius.circular(size * .18),
                  border: Border.all(color: outline),
                  boxShadow: softShadow(context),
                ),
              ),
            ),
            Positioned(
              top: size * .13,
              child: Container(
                width: size * .60,
                height: size * .54,
                decoration: BoxDecoration(
                  color: face,
                  shape: BoxShape.circle,
                  border: Border.all(color: outline, width: 2),
                  boxShadow: softShadow(context),
                ),
              ),
            ),
            Positioned(top: size * .32, left: size * .39, child: _eye()),
            Positioned(top: size * .32, right: size * .39, child: _eye()),
            Positioned(
              top: size * .44,
              child: Container(
                width: size * .17,
                height: size * .06,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.9),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Positioned(
              top: size * .04,
              child: Transform.rotate(
                angle: -.08,
                child: Container(
                  width: size * .56,
                  height: size * .18,
                  decoration: BoxDecoration(
                    color: CalmTheme.ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: size * .16,
                      height: size * .06,
                      margin: EdgeInsets.only(right: size * .05),
                      decoration: BoxDecoration(color: CalmTheme.orange, borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ),
            if (mood == MascotMood.wave)
              Positioned(
                right: size * .05,
                bottom: size * .31,
                child: Transform.rotate(
                  angle: -.55,
                  child: Container(
                    width: size * .10,
                    height: size * .30,
                    decoration: BoxDecoration(color: face, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ),
            if (mood == MascotMood.focus)
              Positioned(
                right: size * .18,
                top: size * .18,
                child: Icon(Icons.auto_awesome_rounded, color: CalmTheme.orange, size: size * .18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _eye() {
    return Container(
      width: size * .055,
      height: size * .09,
      decoration: BoxDecoration(color: CalmTheme.ink, borderRadius: BorderRadius.circular(999)),
    );
  }
}

class CalmStudentApp extends StatefulWidget {
  const CalmStudentApp({
    super.key,
    required this.api,
    required this.user,
    required this.onLogout,
    required this.onThemeToggle,
    required this.themeMode,
    required this.onUserChanged,
  });

  final ApiClient api;
  final Map<String, dynamic> user;
  final VoidCallback onLogout;
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;
  final ValueChanged<Map<String, dynamic>> onUserChanged;

  @override
  State<CalmStudentApp> createState() => _CalmStudentAppState();
}

class _CalmStudentAppState extends State<CalmStudentApp> {
  int index = 0;
  bool loading = true;
  List<dynamic> notes = [];
  List<dynamic> history = [];
  Map<String, dynamic> progress = {};

  int get userId => (widget.user['id'] as num?)?.toInt() ?? 1;
  String get firstName => widget.user['full_name']?.toString().split(' ').first ?? 'Scholar';

  final mainTabs = const [
    AppTab('Home', Icons.home_rounded),
    AppTab('Tutor', Icons.smart_toy_rounded),
    AppTab('Tasks', Icons.checklist_rounded),
    AppTab('Library', Icons.folder_rounded),
    AppTab('Profile', Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        widget.api.notes(userId),
        widget.api.history(userId),
        widget.api.progress(userId),
      ]);
      notes = results[0] as List<dynamic>;
      history = results[1] as List<dynamic>;
      progress = results[2] as Map<String, dynamic>;
    } catch (_) {
      // Keep previous local values and allow the UI to remain usable.
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      body: CalmBackground(
        child: SafeArea(
          child: desktop ? _desktopShell() : _mobileShell(),
        ),
      ),
      bottomNavigationBar: desktop
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: mainTabs
                  .map((tab) => NavigationDestination(icon: Icon(tab.icon), label: tab.label))
                  .toList(),
            ),
    );
  }

  Widget _desktopShell() {
    return Row(
      children: [
        SizedBox(
          width: 248,
          child: CalmSidebar(
            tabs: mainTabs,
            selected: index,
            onSelect: (value) => setState(() => index = value),
            onLogout: widget.onLogout,
            user: widget.user,
          ),
        ),
        Expanded(
          child: Column(
            children: [
              CalmTopBar(
                title: mainTabs[index].label,
                onRefresh: refresh,
                onThemeToggle: widget.onThemeToggle,
                themeMode: widget.themeMode,
              ),
              Expanded(child: _content()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileShell() {
    return Column(
      children: [
        CalmTopBar(
          title: mainTabs[index].label,
          onRefresh: refresh,
          onThemeToggle: widget.onThemeToggle,
          themeMode: widget.themeMode,
          compact: true,
        ),
        Expanded(child: _content()),
      ],
    );
  }

  Widget _content() {
    final data = StudentSnapshot(notes: notes, history: history, progress: progress, user: widget.user);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: RefreshIndicator(
        key: ValueKey(index),
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 90),
          child: switch (index) {
            0 => CalmHome(
                firstName: firstName,
                data: data,
                loading: loading,
                goTutor: () => setState(() => index = 1),
                goTasks: () => setState(() => index = 2),
                goLibrary: () => setState(() => index = 3),
              ),
            1 => CalmTutor(api: widget.api, userId: userId, notes: notes),
            2 => CalmTasks(data: data, api: widget.api, userId: userId, onChanged: refresh),
            3 => CalmLibrary(api: widget.api, userId: userId, notes: notes, onChanged: refresh),
            _ => CalmProfile(
                user: widget.user,
                apiBase: widget.api.baseUrl,
                onLogout: widget.onLogout,
                onThemeToggle: widget.onThemeToggle,
                themeMode: widget.themeMode,
                api: widget.api,
                userId: userId,
                onUserChanged: widget.onUserChanged,
              ),
          },
        ),
      ),
    );
  }
}

class StudentSnapshot {
  StudentSnapshot({required this.notes, required this.history, required this.progress, required this.user});
  final List<dynamic> notes;
  final List<dynamic> history;
  final Map<String, dynamic> progress;
  final Map<String, dynamic> user;

  int get average => (progress['average_score'] as num?)?.toInt() ?? 76;
  int get streak => (progress['streak_days'] as num?)?.toInt() ?? 7;
  int get minutes => ((progress['study_seconds'] as num?)?.toInt() ?? 7200) ~/ 60;
  int get level => max(1, (minutes / 60).floor() + 1);
  int get xp => min(980, minutes * 4 + history.length * 25);
}

class CalmHome extends StatelessWidget {
  const CalmHome({
    super.key,
    required this.firstName,
    required this.data,
    required this.loading,
    required this.goTutor,
    required this.goTasks,
    required this.goLibrary,
  });

  final String firstName;
  final StudentSnapshot data;
  final bool loading;
  final VoidCallback goTutor;
  final VoidCallback goTasks;
  final VoidCallback goLibrary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SoftCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 720;
              final text = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi $firstName 👋', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const SoftText('Let’s keep today simple. I picked a focused plan for you.'),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        CalmPill(icon: Icons.local_fire_department_rounded, label: '${data.streak}-day streak'),
                        CalmPill(icon: Icons.school_rounded, label: '${data.average}% ready'),
                        CalmPill(icon: Icons.workspace_premium_rounded, label: 'Level ${data.level}'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PrimaryCalmButton(label: 'Start today’s plan', icon: Icons.play_arrow_rounded, onTap: goTasks),
                  ],
                ),
              );
              final mascot = const StudentMascot(size: 150, mood: MascotMood.happy);
              if (wide) return Row(children: [text, mascot]);
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [mascot, const SizedBox(height: 14), text]);
            },
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveCalmGrid(
          minWidth: 320,
          children: [
            StudyBrainCard(onStart: goTutor),
            DailyFlowCard(onStart: goTasks),
          ],
        ),
        const SizedBox(height: 16),
        ResponsiveCalmGrid(
          minWidth: 240,
          children: [
            CalmMetric(title: 'Today', value: '45 min', subtitle: 'recommended focus', icon: Icons.timer_rounded, color: CalmTheme.teal),
            CalmMetric(title: 'Exam readiness', value: '${data.average}%', subtitle: 'steady progress', icon: Icons.insights_rounded, color: CalmTheme.green),
            CalmMetric(title: 'XP', value: '${data.xp}', subtitle: 'keep building', icon: Icons.auto_awesome_rounded, color: CalmTheme.orange),
          ],
        ),
        const SizedBox(height: 16),
        NoteIntelligenceCard(notesCount: data.notes.length, onUpload: goLibrary),
      ],
    );
  }
}

class StudyBrainCard extends StatelessWidget {
  const StudyBrainCard({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleIcon(icon: Icons.psychology_rounded, color: CalmTheme.purple),
              const SizedBox(width: 12),
              Expanded(child: Text('AI Study Brain', style: Theme.of(context).textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: 12),
          const SoftText('Your recursion score dropped a little. Spend 25 minutes there before moving to trees.'),
          const SizedBox(height: 14),
          PrimaryCalmButton(label: 'Ask my tutor', icon: Icons.chat_rounded, onTap: onStart, compact: true),
        ],
      ),
    );
  }
}

class DailyFlowCard extends StatelessWidget {
  const DailyFlowCard({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final tasks = const ['20 min recap', '10 MCQs', 'Weak topic review', 'AI explanation'];
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleIcon(icon: Icons.checklist_rounded, color: CalmTheme.teal),
              const SizedBox(width: 12),
              Expanded(child: Text('Today’s Flow', style: Theme.of(context).textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < tasks.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(radius: 13, backgroundColor: CalmTheme.teal.withOpacity(.12), child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tasks[i], style: const TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          const SizedBox(height: 4),
          SecondaryCalmButton(label: 'View tasks', icon: Icons.arrow_forward_rounded, onTap: onStart),
        ],
      ),
    );
  }
}

class NoteIntelligenceCard extends StatelessWidget {
  const NoteIntelligenceCard({super.key, required this.notesCount, required this.onUpload});
  final int notesCount;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          const StudentMascot(size: 92, mood: MascotMood.focus),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Advanced Note Intelligence', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                SoftText(notesCount == 0
                    ? 'Upload one note and I’ll help turn it into summaries, flashcards, quizzes, and study actions.'
                    : 'You have $notesCount notes. Open your library to generate study materials.'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SecondaryCalmButton(label: 'Library', icon: Icons.folder_rounded, onTap: onUpload),
        ],
      ),
    );
  }
}

class CalmTutor extends StatefulWidget {
  const CalmTutor({super.key, required this.api, required this.userId, required this.notes});
  final ApiClient api;
  final int userId;
  final List<dynamic> notes;

  @override
  State<CalmTutor> createState() => _CalmTutorState();
}

class _CalmTutorState extends State<CalmTutor> {
  final input = TextEditingController();
  final messages = <TutorMessage>[
    TutorMessage(false, 'Hi, I’m your study buddy. Ask me one question, and I’ll explain it calmly step by step.'),
  ];
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionIntro(
          icon: Icons.smart_toy_rounded,
          title: 'AI Tutor',
          subtitle: 'A calm ChatGPT-style tutor with note context, image upload, and step-by-step answers.',
          mascot: const StudentMascot(size: 100, mood: MascotMood.wave),
        ),
        const SizedBox(height: 16),
        SoftCard(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: min(640, MediaQuery.sizeOf(context).height - 190),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleIcon(icon: Icons.psychology_rounded, color: CalmTheme.teal),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Tutor is ready', style: TextStyle(fontWeight: FontWeight.w900))),
                      CalmPill(icon: Icons.mic_rounded, label: 'Voice ready', onTap: () => toast(context, 'Voice tutor button is active. Connect speech-to-text for live voice input.')),
                    ],
                  ),
                ),
                Divider(height: 1, color: dividerColor(context)),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => TutorBubble(message: messages[i]),
                  ),
                ),
                Divider(height: 1, color: dividerColor(context)),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      IconButton.filledTonal(onPressed: _pickImage, icon: const Icon(Icons.attach_file_rounded)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: input,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(hintText: 'Ask one question...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        onPressed: sending ? null : _send,
                        child: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => messages.add(TutorMessage(true, 'Uploaded image: ${result.files.single.name}. Please explain this calmly.')));
    }
  }

  Future<void> _send() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add(TutorMessage(true, text));
      input.clear();
      sending = true;
    });
    try {
      final noteId = widget.notes.isNotEmpty ? (widget.notes.first as Map)['id'] as int? : null;
      final response = await widget.api.aiChat(widget.userId, noteId, text);
      final answer = response['answer']?.toString() ?? response['response']?.toString() ?? response['message']?.toString() ?? fallbackTutor(text);
      setState(() => messages.add(TutorMessage(false, answer)));
    } catch (_) {
      setState(() => messages.add(TutorMessage(false, fallbackTutor(text))));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }
}

String fallbackTutor(String text) {
  return 'Let’s solve it calmly:\n\n1. Identify the main idea in "$text".\n2. Break it into smaller parts.\n3. Try one example.\n4. Test yourself with a short quiz.\n\nI’ll give stronger live answers when the backend AI route is connected.';
}


class CalmTasks extends StatefulWidget {
  const CalmTasks({
    super.key,
    required this.data,
    required this.api,
    required this.userId,
    required this.onChanged,
  });

  final StudentSnapshot data;
  final ApiClient api;
  final int userId;
  final VoidCallback onChanged;

  @override
  State<CalmTasks> createState() => _CalmTasksState();
}

class _CalmTasksState extends State<CalmTasks> {
  final List<bool> done = [false, false, false, false];
  bool saving = false;

  final tasks = const [
    ('Recap yesterday’s topic', '20 min', Icons.menu_book_rounded, 'recap'),
    ('Answer 10 practice MCQs', '15 min', Icons.quiz_rounded, 'quiz'),
    ('Review one weak topic', '25 min', Icons.psychology_rounded, 'weak-topic'),
    ('Ask AI for one explanation', '10 min', Icons.smart_toy_rounded, 'ai-tutor'),
  ];

  int get completed => done.where((x) => x).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionIntro(
          icon: Icons.checklist_rounded,
          title: 'Today’s Plan',
          subtitle: 'Only four focused actions. Tap a task when you finish it and ExamAI saves your progress.',
          mascot: const StudentMascot(size: 100, mood: MascotMood.focus),
        ),
        const SizedBox(height: 16),
        ResponsiveCalmGrid(
          minWidth: 260,
          children: [
            CalmMetric(title: 'Streak', value: '${widget.data.streak} days', subtitle: 'steady habit', icon: Icons.local_fire_department_rounded, color: CalmTheme.orange),
            CalmMetric(title: 'Level', value: '${widget.data.level}', subtitle: '${widget.data.xp + completed * 15} XP earned', icon: Icons.workspace_premium_rounded, color: CalmTheme.purple),
            CalmMetric(title: 'Today', value: '$completed / ${tasks.length}', subtitle: 'tasks completed', icon: Icons.check_circle_rounded, color: CalmTheme.green),
          ],
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < tasks.length; i++)
                CalmTaskTile(
                  number: i + 1,
                  title: tasks[i].$1,
                  duration: tasks[i].$2,
                  icon: tasks[i].$3,
                  done: done[i],
                  onTap: () => _toggleTask(i),
                ),
              const SizedBox(height: 8),
              PrimaryCalmButton(
                label: saving ? 'Saving progress...' : 'Save today’s progress',
                icon: Icons.cloud_done_rounded,
                onTap: saving ? null : _saveProgress,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gamification, gently', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const SoftText('XP, levels, streaks and badges motivate students without making the app noisy. Tap a badge to see how it unlocks.'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  CalmPill(icon: Icons.star_rounded, label: 'Quiz Master', onTap: () => showFeatureSheet(context, 'Quiz Master', 'Unlock by completing quizzes and improving your score.')),
                  CalmPill(icon: Icons.local_fire_department_rounded, label: '7-day streak', onTap: () => showFeatureSheet(context, '7-day streak', 'Unlock by studying every day for one week.')),
                  CalmPill(icon: Icons.emoji_events_rounded, label: 'Top 10%', onTap: () => showFeatureSheet(context, 'Top 10%', 'Unlock by ranking high on practice performance.')),
                  CalmPill(icon: Icons.auto_awesome_rounded, label: 'Focus Hero', onTap: () => showFeatureSheet(context, 'Focus Hero', 'Unlock by finishing daily plans consistently.')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleTask(int index) {
    setState(() => done[index] = !done[index]);
    toast(context, done[index] ? 'Task completed. Nice work.' : 'Task marked incomplete.');
  }

  Future<void> _saveProgress() async {
    setState(() => saving = true);
    try {
      final seconds = completed * 15 * 60;
      await widget.api.recordStudyTime(widget.userId, null, 'daily-plan:$completed/${tasks.length}', seconds);
      widget.onChanged();
      if (mounted) {
        showFeatureSheet(
          context,
          'Progress saved',
          'Your completed tasks, study time, streak, and XP have been saved to the backend progress system.',
        );
      }
    } catch (e) {
      if (mounted) toast(context, 'Could not save progress: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class CalmLibrary extends StatefulWidget {
  const CalmLibrary({super.key, required this.api, required this.userId, required this.notes, required this.onChanged});
  final ApiClient api;
  final int userId;
  final List<dynamic> notes;
  final VoidCallback onChanged;

  @override
  State<CalmLibrary> createState() => _CalmLibraryState();
}

class _CalmLibraryState extends State<CalmLibrary> {
  final title = TextEditingController();
  final text = TextEditingController();
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionIntro(
          icon: Icons.folder_rounded,
          title: 'Library',
          subtitle: 'Upload once. Generate summaries, flashcards, quizzes and study actions later.',
          mascot: const StudentMascot(size: 100, mood: MascotMood.happy),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a note', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 10),
              TextField(controller: text, maxLines: 5, decoration: const InputDecoration(labelText: 'Paste text note')),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  PrimaryCalmButton(label: busy ? 'Saving...' : 'Save text', icon: Icons.save_rounded, onTap: busy ? null : _saveText, compact: true),
                  SecondaryCalmButton(label: 'Upload file', icon: Icons.upload_file_rounded, onTap: _upload),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.notes.isEmpty)
          const EmptyCalmState(
            icon: Icons.folder_open_rounded,
            title: 'No notes yet',
            message: 'Upload a note and ExamAI will help turn it into learning materials.',
          )
        else
          ResponsiveCalmGrid(
            minWidth: 280,
            children: widget.notes.map((note) {
              final map = note as Map;
              return SoftCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleIcon(icon: Icons.description_rounded, color: CalmTheme.teal),
                  title: Text(map['title']?.toString() ?? 'Note', style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(map['file_name']?.toString() ?? 'Text note'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _saveText() async {
    if (title.text.trim().isEmpty || text.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      await widget.api.createTextNote(widget.userId, title.text, text.text);
      title.clear();
      text.clear();
      widget.onChanged();
      if (mounted) toast(context, 'Note saved.');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    try {
      await widget.api.uploadFile(widget.userId, result.files.single.name, result.files.single);
      widget.onChanged();
      if (mounted) toast(context, 'File uploaded.');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    }
  }
}

class CalmProfile extends StatefulWidget {
  const CalmProfile({
    super.key,
    required this.user,
    required this.apiBase,
    required this.onLogout,
    required this.onThemeToggle,
    required this.themeMode,
    required this.api,
    required this.userId,
    required this.onUserChanged,
  });

  final Map<String, dynamic> user;
  final String apiBase;
  final VoidCallback onLogout;
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;
  final ApiClient api;
  final int userId;
  final ValueChanged<Map<String, dynamic>> onUserChanged;

  @override
  State<CalmProfile> createState() => _CalmProfileState();
}

class _CalmProfileState extends State<CalmProfile> {
  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController bio;
  String avatar = 'robot';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.user['full_name']?.toString() ?? '');
    email = TextEditingController(text: widget.user['email']?.toString() ?? '');
    bio = TextEditingController(text: widget.user['bio']?.toString() ?? '');
    avatar = widget.user['avatar_character']?.toString() ?? 'robot';
  }

  @override
  void didUpdateWidget(covariant CalmProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      name.text = widget.user['full_name']?.toString() ?? '';
      email.text = widget.user['email']?.toString() ?? '';
      bio.text = widget.user['bio']?.toString() ?? '';
      avatar = widget.user['avatar_character']?.toString() ?? 'robot';
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    bio.dispose();
    super.dispose();
  }

  String? get profileImageUrl {
    final value = widget.user['profile_image_url']?.toString();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http')) return value;
    return '${widget.apiBase}$value';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionIntro(
          icon: Icons.person_rounded,
          title: widget.user['full_name']?.toString() ?? 'Student',
          subtitle: 'Edit your profile, secure your account, and keep advanced tools neatly tucked away.',
          mascot: ProfileAvatarPreview(
            size: 104,
            avatar: avatar,
            imageUrl: profileImageUrl,
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile details', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    ProfileAvatarPreview(size: 112, avatar: avatar, imageUrl: profileImageUrl),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: saving ? null : _uploadProfilePicture,
                          icon: const Icon(Icons.photo_camera_rounded),
                          label: const Text('Upload profile picture'),
                        ),
                        OutlinedButton.icon(
                          onPressed: saving ? null : _chooseAvatar,
                          icon: const Icon(Icons.emoji_emotions_rounded),
                          label: const Text('Change avatar character'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bio,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Short bio / study goal',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: saving ? null : _saveProfile,
                icon: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: Text(saving ? 'Saving...' : 'Save profile changes'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Security', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const SoftText('Use password changes and device security where your phone or computer supports it.'),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.password_rounded),
                title: const Text('Change password'),
                subtitle: const Text('Update your account password safely.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _changePassword,
              ),
              const Divider(),
              const BiometricSecurityTile(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            children: [
              SwitchListTile(
                value: widget.themeMode == ThemeMode.dark,
                onChanged: (_) => widget.onThemeToggle(),
                secondary: const Icon(Icons.contrast_rounded),
                title: const Text('Dark mode'),
                subtitle: const Text('Light mode stays default and calm.'),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Logout'),
                onTap: widget.onLogout,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('More tools', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const SoftText('Advanced features are available, but hidden here so students are not overwhelmed.'),
              const SizedBox(height: 14),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Explore advanced tools'),
                children: const [
                  MoreToolTile(icon: Icons.groups_rounded, title: 'Community', subtitle: 'Groups, rooms and leaderboards'),
                  MoreToolTile(icon: Icons.storefront_rounded, title: 'Marketplace', subtitle: 'Sell notes, flashcards and tutoring'),
                  MoreToolTile(icon: Icons.school_rounded, title: 'Teacher Dashboard', subtitle: 'Classes, assignments and analytics'),
                  MoreToolTile(icon: Icons.work_rounded, title: 'Career Hub', subtitle: 'Internships, CVs and scholarships'),
                  MoreToolTile(icon: Icons.notifications_rounded, title: 'Notifications', subtitle: 'Reminders and exam alerts'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty) {
      toast(context, 'Name and email are required.');
      return;
    }
    setState(() => saving = true);
    try {
      final updated = await widget.api.updateProfile(
        widget.userId,
        fullName: name.text,
        email: email.text,
        avatarCharacter: avatar,
        bio: bio.text,
      );
      widget.onUserChanged(updated);
      if (mounted) toast(context, 'Profile updated.');
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _uploadProfilePicture() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;
    setState(() => saving = true);
    try {
      final updated = await widget.api.uploadProfilePicture(widget.userId, result.files.single);
      widget.onUserChanged(updated);
      if (mounted) toast(context, 'Profile picture uploaded.');
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _chooseAvatar() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose avatar character', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final option in avatarOptions)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context, option.key),
                    child: Container(
                      width: 92,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: option.key == avatar ? CalmTheme.teal.withOpacity(.12) : cardColor(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: option.key == avatar ? CalmTheme.teal : dividerColor(context)),
                      ),
                      child: Column(
                        children: [
                          Icon(option.icon, color: option.color, size: 34),
                          const SizedBox(height: 8),
                          Text(option.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => avatar = selected);
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    bool busy = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
              const SizedBox(height: 10),
              TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
              const SizedBox(height: 10),
              TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
            ],
          ),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (next.text.length < 6) {
                        toast(context, 'New password must be at least 6 characters.');
                        return;
                      }
                      if (next.text != confirm.text) {
                        toast(context, 'New passwords do not match.');
                        return;
                      }
                      setDialogState(() => busy = true);
                      try {
                        await widget.api.changePassword(widget.userId, current.text, next.text);
                        if (context.mounted) Navigator.pop(context);
                        if (mounted) toast(this.context, 'Password changed.');
                      } catch (e) {
                        if (context.mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
                      } finally {
                        if (context.mounted) setDialogState(() => busy = false);
                      }
                    },
              child: Text(busy ? 'Saving...' : 'Update password'),
            ),
          ],
        ),
      ),
    );
    current.dispose();
    next.dispose();
    confirm.dispose();
  }
}

class ProfileAvatarPreview extends StatelessWidget {
  const ProfileAvatarPreview({super.key, required this.size, required this.avatar, this.imageUrl});
  final double size;
  final String avatar;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final option = avatarOptions.firstWhere((item) => item.key == avatar, orElse: () => avatarOptions.first);
    if (imageUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: option.color.withOpacity(.12),
        backgroundImage: NetworkImage(imageUrl!),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: option.color.withOpacity(.12),
        border: Border.all(color: option.color.withOpacity(.32)),
        boxShadow: softShadow(context),
      ),
      child: Icon(option.icon, size: size * .42, color: option.color),
    );
  }
}

class AvatarOption {
  const AvatarOption(this.key, this.label, this.icon, this.color);
  final String key;
  final String label;
  final IconData icon;
  final Color color;
}

const avatarOptions = [
  AvatarOption('robot', 'Robot', Icons.smart_toy_rounded, CalmTheme.teal),
  AvatarOption('fox', 'Fox', Icons.pets_rounded, CalmTheme.orange),
  AvatarOption('owl', 'Owl', Icons.school_rounded, CalmTheme.indigo),
  AvatarOption('cat', 'Cat', Icons.cruelty_free_rounded, CalmTheme.rose),
  AvatarOption('panda', 'Panda', Icons.emoji_nature_rounded, CalmTheme.green),
  AvatarOption('star', 'Star', Icons.auto_awesome_rounded, CalmTheme.purple),
  AvatarOption('rocket', 'Rocket', Icons.rocket_launch_rounded, CalmTheme.blue),
];

class AppTab {
  const AppTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

class TutorMessage {
  TutorMessage(this.me, this.text);
  final bool me;
  final String text;
}

class CalmBackground extends StatelessWidget {
  const CalmBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xff07111d), Color(0xff0d1b2a), Color(0xff07111d)]
              : const [Color(0xfffffbf4), Color(0xffeefcf8), Color(0xfff7fbfa)],
        ),
      ),
      child: child,
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, this.child, this.padding = const EdgeInsets.all(18)});
  final Widget? child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(.055) : Colors.white.withOpacity(.88),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: dark ? Colors.white.withOpacity(.08) : const Color(0xffdcefed)),
        boxShadow: softShadow(context),
      ),
      child: child,
    );
  }
}

class PrimaryCalmButton extends StatelessWidget {
  const PrimaryCalmButton({super.key, required this.label, required this.icon, required this.onTap, this.compact = false});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: compact ? 18 : 20),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18, vertical: compact ? 12 : 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class SecondaryCalmButton extends StatelessWidget {
  const SecondaryCalmButton({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class CalmSidebar extends StatelessWidget {
  const CalmSidebar({super.key, required this.tabs, required this.selected, required this.onSelect, required this.onLogout, required this.user});
  final List<AppTab> tabs;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(border: Border(right: BorderSide(color: dividerColor(context)))),
      child: Column(
        children: [
          const Row(
            children: [
              StudentMascot(size: 58, mood: MascotMood.happy),
              SizedBox(width: 10),
              Expanded(child: Text('ExamAI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.builder(
              itemCount: tabs.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  selected: selected == i,
                  selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(.10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  leading: Icon(tabs[i].icon),
                  title: Text(tabs[i].label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  onTap: () => onSelect(i),
                ),
              ),
            ),
          ),
          SoftCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const StudentMascot(size: 48),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user['full_name']?.toString() ?? 'Student',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(onPressed: onLogout, icon: const Icon(Icons.logout_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CalmTopBar extends StatelessWidget {
  const CalmTopBar({super.key, required this.title, required this.onRefresh, required this.onThemeToggle, required this.themeMode, this.compact = false});
  final String title;
  final VoidCallback onRefresh;
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 72 : 66,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: dividerColor(context)))),
      child: Row(
        children: [
          if (compact) const StudentMascot(size: 44),
          if (compact) const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const Spacer(),
          IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
          IconButton(
            onPressed: onThemeToggle,
            icon: Icon(themeMode == ThemeMode.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
          ),
        ],
      ),
    );
  }
}

class SectionIntro extends StatelessWidget {
  const SectionIntro({super.key, required this.icon, required this.title, required this.subtitle, required this.mascot});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget mascot;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 640;
          final content = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleIcon(icon: icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                SoftText(subtitle),
              ],
            ),
          );
          if (wide) return Row(children: [content, mascot]);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [mascot, const SizedBox(height: 12), content]);
        },
      ),
    );
  }
}

class ResponsiveCalmGrid extends StatelessWidget {
  const ResponsiveCalmGrid({super.key, required this.children, this.minWidth = 220, this.spacing = 14});
  final List<Widget> children;
  final double minWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = max(1, constraints.maxWidth ~/ minWidth);
        final width = (constraints.maxWidth - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) => SizedBox(width: width, child: child)).toList(),
        );
      },
    );
  }
}

class CalmMetric extends StatelessWidget {
  const CalmMetric({super.key, required this.title, required this.value, required this.subtitle, required this.icon, required this.color});
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleIcon(icon: icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: muted(context), fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}


class CalmTaskTile extends StatelessWidget {
  const CalmTaskTile({
    super.key,
    required this.number,
    required this.title,
    required this.duration,
    required this.icon,
    required this.done,
    this.onTap,
  });

  final int number;
  final String title;
  final String duration;
  final IconData icon;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: done ? CalmTheme.green.withOpacity(.08) : Theme.of(context).colorScheme.primary.withOpacity(.05),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: done ? CalmTheme.green.withOpacity(.35) : dividerColor(context)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: done ? CalmTheme.green.withOpacity(.14) : Theme.of(context).colorScheme.primary.withOpacity(.12),
                  child: Icon(done ? Icons.check_rounded : icon, color: done ? CalmTheme.green : Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Text('$number.', style: TextStyle(color: muted(context), fontWeight: FontWeight.w900)),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
                Text(duration, style: TextStyle(color: muted(context), fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class TutorBubble extends StatelessWidget {
  const TutorBubble({super.key, required this.message});
  final TutorMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.me ? Theme.of(context).colorScheme.primary : cardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dividerColor(context)),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            height: 1.45,
            color: message.me ? Colors.white : null,
            fontWeight: message.me ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class EmptyCalmState extends StatelessWidget {
  const EmptyCalmState({super.key, required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          const StudentMascot(size: 96, mood: MascotMood.happy),
          const SizedBox(height: 12),
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          SoftText(message, center: true),
        ],
      ),
    );
  }
}


class MoreToolTile extends StatelessWidget {
  const MoreToolTile({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => showFeatureSheet(context, title, _messageFor(title)),
      leading: CircleIcon(icon: icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  String _messageFor(String title) {
    switch (title) {
      case 'Community':
        return 'Opens school groups, study rooms, leaderboards, and collaborative learning features.';
      case 'Marketplace':
        return 'Opens note packs, flashcard packs, tutoring offers, and future paid student resources.';
      case 'Teacher Dashboard':
        return 'Opens class management, assignments, student analytics, and teacher reporting.';
      case 'Career Hub':
        return 'Opens internships, CV builder, scholarship alerts, and portfolio tools.';
      case 'Notifications':
        return 'Opens reminders, exam countdown alerts, daily challenges, and streak notifications.';
      default:
        return 'This tool is connected as an advanced module and ready for full backend expansion.';
    }
  }
}

class SoftText extends StatelessWidget {
  const SoftText(this.text, {super.key, this.size = 14, this.center = false});
  final String text;
  final double size;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: TextStyle(color: muted(context), height: 1.45, fontSize: size, fontWeight: FontWeight.w600),
    );
  }
}


class CalmPill extends StatelessWidget {
  const CalmPill({super.key, required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );

    if (onTap == null) return pill;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: pill,
      ),
    );
  }
}

class CircleIcon extends StatelessWidget {
  const CircleIcon({super.key, required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: color.withOpacity(.12),
      child: Icon(icon, color: color),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CalmTheme.rose.withOpacity(.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CalmTheme.rose.withOpacity(.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: CalmTheme.rose),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}


class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isReady() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported || canCheck;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> availableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  static Future<String> deviceSecurityLabel() async {
    final types = await availableTypes();
    if (types.contains(BiometricType.face)) return 'Face unlock available';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint available';
    if (await isReady()) return 'Device security available';
    return 'Not available on this device';
  }

  static Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

class BiometricSecurityTile extends StatefulWidget {
  const BiometricSecurityTile({super.key});

  @override
  State<BiometricSecurityTile> createState() => _BiometricSecurityTileState();
}

class _BiometricSecurityTileState extends State<BiometricSecurityTile> {
  bool loading = true;
  bool available = false;
  bool enabled = false;
  String label = 'Checking device security...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isReady = await BiometricAuthService.isReady();
    final deviceLabel = await BiometricAuthService.deviceSecurityLabel();
    if (!mounted) return;
    setState(() {
      available = isReady;
      enabled = prefs.getBool('biometric_enabled') ?? false;
      label = deviceLabel;
      loading = false;
    });
  }

  Future<void> _toggle(bool next) async {
    if (loading) return;
    if (!available) {
      toast(context, 'This device has no supported Face ID, fingerprint, Windows Hello, or screen lock security.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (next) {
      final ok = await BiometricAuthService.authenticate(reason: 'Confirm device security to protect ExamAI');
      if (!mounted) return;
      if (!ok) {
        toast(context, 'Security setup cancelled.');
        return;
      }
      await prefs.setBool('biometric_enabled', true);
      setState(() => enabled = true);
      toast(context, 'Device security enabled for ExamAI.');
    } else {
      await prefs.setBool('biometric_enabled', false);
      if (mounted) setState(() => enabled = false);
      toast(context, 'Device security disabled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: enabled,
      onChanged: available ? _toggle : null,
      secondary: Icon(available ? Icons.fingerprint_rounded : Icons.lock_open_rounded),
      title: const Text('Face ID / fingerprint / device lock'),
      subtitle: Text(loading ? 'Checking security options...' : label),
    );
  }
}

Color muted(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(.68) : CalmTheme.softInk;
}

Color cardColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(.06) : Colors.white;
}

Color dividerColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(.08) : const Color(0xffdcefed);
}

List<BoxShadow> softShadow(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return [
    BoxShadow(
      color: dark ? Colors.black.withOpacity(.20) : const Color(0xff0f766e).withOpacity(.08),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
  ];
}


void showFeatureSheet(BuildContext context, String title, String message) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleIcon(icon: Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
              ],
            ),
            const SizedBox(height: 12),
            SoftText(message),
            const SizedBox(height: 18),
            PrimaryCalmButton(
              label: 'Got it',
              icon: Icons.done_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    },
  );
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
