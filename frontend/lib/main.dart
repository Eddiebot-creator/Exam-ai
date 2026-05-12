import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

const brandLogoAsset = 'assets/brand/examai_logo.png';
const brandSplashAsset = 'assets/brand/examai_splash.png';

void main() {
  runApp(const ExamAssistantApp());
}

class ExamAssistantApp extends StatelessWidget {
  const ExamAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'ExamAI',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const AppGate(),
        );
      },
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool? seenOnboarding;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
          () => seenOnboarding = prefs.getBool('seen_onboarding') ?? false);
    }
  }

  Future<void> finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) setState(() => seenOnboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    if (seenOnboarding == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return seenOnboarding!
        ? const AuthScreen()
        : OnboardingScreen(onDone: finish);
  }
}

class AppTheme {
  static const teal = Color(0xff087f78);
  static const mint = Color(0xffb8f3df);
  static const coral = Color(0xffff6b5f);
  static const amber = Color(0xffffb84d);
  static const ink = Color(0xff18212f);
  static const paper = Color(0xfff6f4ee);
  static const night = Color(0xff111722);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
      primary: teal,
      secondary: coral,
      tertiary: amber,
      surface: const Color(0xfffffbf4),
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: mint,
      brightness: Brightness.dark,
      primary: mint,
      secondary: coral,
      tertiary: amber,
      surface: const Color(0xff17202c),
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: night,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(fontWeight: FontWeight.w800),
        headlineSmall: TextStyle(fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ),
    );
  }
}

class ApiClient {
  ApiClient({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8010',
    ),
  });

  final String baseUrl;

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await _post(
      '/auth/register',
      {'full_name': name.trim(), 'email': email.trim(), 'password': password},
    );
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _post(
        '/auth/login', {'email': email.trim(), 'password': password});
    return _decodeMap(response);
  }

  Future<List<dynamic>> notes(int userId) async {
    final response = await _get('/notes?user_id=$userId');
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> createTextNote(
      int userId, String title, String text) async {
    final response = await _post('/notes/text',
        {'user_id': userId, 'title': title.trim(), 'text': text.trim()});
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> uploadFile(
      int userId, String title, PlatformFile file) async {
    if (file.path == null) {
      throw const ApiException(
          'This file cannot be opened from the selected location.');
    }
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/notes/upload'));
    request.fields['user_id'] = userId.toString();
    request.fields['title'] = title.trim();
    request.files.add(await http.MultipartFile.fromPath('file', file.path!));
    try {
      final response =
          await request.send().timeout(const Duration(seconds: 60));
      final body = await response.stream.bytesToString();
      return _decodeMap(http.Response(body, response.statusCode));
    } on SocketException {
      throw ApiException.offline(baseUrl);
    } on TimeoutException {
      throw const ApiException(
          'The upload took too long. Try a smaller file or check the backend.');
    }
  }

  Future<Map<String, dynamic>> summarize(
      int userId, int noteId, String mode) async {
    final response =
        await _post('/ai/summarize/$noteId', {'user_id': userId, 'mode': mode});
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> generateMcq(
      int noteId, String difficulty, String mode, int count) async {
    final response = await _post('/ai/generate-mcq/$noteId',
        {'difficulty': difficulty, 'mode': mode, 'count': count});
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> generateFlashcards(int noteId) async {
    final response = await http
        .post(Uri.parse('$baseUrl/ai/generate-flashcards/$noteId'))
        .timeout(const Duration(seconds: 90));
    return _decodeMap(response);
  }

  Future<List<dynamic>> startQuiz(
      int noteId, String mode, String difficulty, int limit) async {
    final response = await _get(
        '/quiz/start/$noteId?mode=$mode&difficulty=$difficulty&limit=$limit');
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> submitQuiz(
    int userId,
    int noteId,
    Map<int, String> answers,
    String mode,
    String difficulty,
    int timeSeconds,
  ) async {
    final response = await _post('/quiz/submit', {
      'user_id': userId,
      'note_id': noteId,
      'answers': answers.map((key, value) => MapEntry(key.toString(), value)),
      'mode': mode,
      'difficulty': difficulty,
      'time_seconds': timeSeconds,
    });
    return _decodeMap(response);
  }

  Future<List<dynamic>> quizHistory(int userId) async {
    final response = await _get('/quiz/history?user_id=$userId');
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> progress(int userId) async {
    final response = await _get('/progress/$userId');
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> subscription(int userId) async {
    final response = await _get('/subscription/status/$userId');
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> updateSubscription(
      int userId, String status) async {
    final response =
        await _post('/subscription/status/$userId', {'status': status});
    return _decodeMap(response);
  }

  Future<List<dynamic>> chatHistory(int userId, int noteId) async {
    final response = await _get('/ai/chat-with-note/$noteId?user_id=$userId');
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> chatWithNote(
      int userId, int noteId, String message) async {
    final response = await _post(
        '/ai/chat-with-note/$noteId', {'user_id': userId, 'message': message});
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> rateFlashcard(int cardId, String rating) async {
    final response =
        await _post('/flashcards/$cardId/rate', {'rating': rating});
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> examPrediction(int noteId) async {
    final response = await _get('/ai/exam-prediction/$noteId');
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> createStudyPlan(
    int userId,
    int? noteId,
    String examDate,
    int dailyMinutes,
    String goal,
  ) async {
    final response = await _post('/planner/create', {
      'user_id': userId,
      'note_id': noteId,
      'exam_date': examDate,
      'daily_minutes': dailyMinutes,
      'goal': goal,
    });
    return _decodeMap(response);
  }

  Future<List<dynamic>> studyPlans(int userId) async {
    final response = await _get('/planner/$userId');
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> preferences(int userId) async {
    final response = await _get('/preferences/$userId');
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> savePreferences(
      int userId, Map<String, dynamic> payload) async {
    final response = await _post('/preferences/$userId', payload);
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> createCheckout(int userId, String plan) async {
    final response = await _post(
        '/payment/create-checkout', {'user_id': userId, 'plan': plan});
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> createClass(int teacherId, String name) async {
    final response =
        await _post('/school/classes', {'teacher_id': teacherId, 'name': name});
    return _decodeMap(response);
  }

  Future<List<dynamic>> teacherClasses(int teacherId) async {
    final response = await _get('/school/classes/$teacherId');
    return _decodeList(response);
  }

  Future<http.Response> _get(String path) async {
    try {
      return await http
          .get(Uri.parse('$baseUrl$path'))
          .timeout(const Duration(seconds: 25));
    } on SocketException {
      throw ApiException.offline(baseUrl);
    } on TimeoutException {
      throw ApiException.timeout(baseUrl);
    }
  }

  Future<http.Response> _post(String path, Map<String, dynamic> payload) async {
    try {
      return await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));
    } on SocketException {
      throw ApiException.offline(baseUrl);
    } on TimeoutException {
      throw ApiException.timeout(baseUrl);
    }
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(body['detail']?.toString() ?? 'Request failed.');
    }
    return body;
  }

  List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode >= 400) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(body['detail']?.toString() ?? 'Request failed.');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  factory ApiException.offline(String baseUrl) {
    return ApiException(
        'Cannot reach the backend at $baseUrl. Start the FastAPI server and try again.');
  }

  factory ApiException.timeout(String baseUrl) {
    return ApiException(
        'The backend at $baseUrl is taking too long to respond.');
  }

  final String message;

  @override
  String toString() => message;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final Future<void> Function() onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int index = 0;

  final pages = const [
    _OnboardingPage(
      icon: Icons.upload_file_rounded,
      title: 'Upload your notes',
      message:
          'Bring PDFs, handouts, and pasted lecture notes into one focused study space.',
      color: AppTheme.teal,
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      title: 'Get summaries and questions',
      message:
          'Choose short notes, detailed study guides, exam focus, likely questions, or weak-topic help.',
      color: AppTheme.coral,
    ),
    _OnboardingPage(
      icon: Icons.emoji_events_rounded,
      title: 'Practice until exam ready',
      message:
          'Use timed quizzes, mock exams, flashcards, progress tracking, and chat with your notes.',
      color: AppTheme.amber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const BrandMark(size: 38),
                  const SizedBox(width: 10),
                  Text('ExamAI', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                      onPressed: widget.onDone, child: const Text('Skip')),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: controller,
                  onPageChanged: (value) => setState(() => index = value),
                  children: pages,
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == i ? 32 : 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: index == i
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: index == pages.length - 1
                        ? widget.onDone
                        : () => controller.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOut),
                    icon: Icon(index == pages.length - 1
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded),
                    label: Text(
                        index == pages.length - 1 ? 'Start studying' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage(
      {required this.icon,
      required this.title,
      required this.message,
      required this.color});

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StudyIllustration(icon: icon, color: color, size: 170),
            const SizedBox(height: 28),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final api = ApiClient();
  final nameController = TextEditingController(text: 'Demo Student');
  final emailController = TextEditingController(text: 'student@example.com');
  final passwordController = TextEditingController(text: 'password123');
  bool isSignup = false;
  bool loading = false;
  bool obscurePassword = true;

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();
    if (email.isEmpty || password.isEmpty || (isSignup && name.isEmpty)) {
      showMessage(context, 'Fill in the required fields first.');
      return;
    }

    setState(() => loading = true);
    try {
      final user = isSignup
          ? await api.register(name, email, password)
          : await api.login(email, password);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => DashboardScreen(api: api, user: user)),
      );
    } catch (error) {
      if (!mounted) return;
      showMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 760;
                  final form = _AuthForm(
                    isSignup: isSignup,
                    loading: loading,
                    obscurePassword: obscurePassword,
                    nameController: nameController,
                    emailController: emailController,
                    passwordController: passwordController,
                    onSubmit: submit,
                    onToggleSignup: () => setState(() => isSignup = !isSignup),
                    onTogglePassword: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  );
                  final stage = _AuthStage(isSignup: isSignup);
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    child: wide
                        ? Row(
                            key: const ValueKey('wide-auth'),
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: stage),
                              const SizedBox(width: 24),
                              SizedBox(width: 420, child: form),
                            ],
                          )
                        : Column(
                            key: const ValueKey('compact-auth'),
                            children: [
                              stage,
                              const SizedBox(height: 18),
                              form,
                            ],
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: ThemeToggle(
        tooltip: theme.brightness == Brightness.dark
            ? 'Use light theme'
            : 'Use dark theme',
      ),
    );
  }
}

class _AuthStage extends StatelessWidget {
  const _AuthStage({required this.isSignup});

  final bool isSignup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.primaryContainer.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.26 : 0.72),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const BrandMark(size: 52),
              const SizedBox(width: 14),
              Text('ExamAI', style: theme.textTheme.displaySmall),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Text(
              isSignup ? 'Build your study cockpit.' : 'Welcome back, scholar.',
              key: ValueKey(isSignup),
              style: theme.textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Upload notes, turn them into smart summaries, practice MCQs, and keep your revision moving.',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: color.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FeaturePill(icon: Icons.bolt_rounded, label: 'Fast summaries'),
              FeaturePill(icon: Icons.quiz_rounded, label: 'MCQ practice'),
              FeaturePill(icon: Icons.style_rounded, label: 'Flashcards'),
              FeaturePill(
                  icon: Icons.emoji_events_rounded, label: 'Quiz scores'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.isSignup,
    required this.loading,
    required this.obscurePassword,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    required this.onToggleSignup,
    required this.onTogglePassword,
  });

  final bool isSignup;
  final bool loading;
  final bool obscurePassword;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final VoidCallback onToggleSignup;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfacePanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isSignup ? 'Create account' : 'Login',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            child: isSignup
                ? Column(
                    children: [
                      TextField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.badge_outlined),
                            labelText: 'Full name'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline_rounded),
                labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              labelText: 'Password',
              suffixIcon: IconButton(
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                onPressed: onTogglePassword,
                icon: Icon(obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: loading ? null : onSubmit,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(isSignup
                    ? Icons.person_add_alt_1_rounded
                    : Icons.login_rounded),
            label: Text(loading
                ? 'Working...'
                : isSignup
                    ? 'Create account'
                    : 'Login'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: loading ? null : onToggleSignup,
            child: Text(isSignup
                ? 'I already have an account'
                : 'Create a new account'),
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api, required this.user});

  final ApiClient api;
  final Map<String, dynamic> user;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> notes = [];
  List<dynamic> history = [];
  Map<String, dynamic>? progress;
  Map<String, dynamic>? subscription;
  bool loading = true;
  int navIndex = 0;

  int get userId => widget.user['id'] as int;

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
        widget.api.quizHistory(userId),
        widget.api.progress(userId),
        widget.api.subscription(userId),
      ]);
      if (!mounted) return;
      setState(() {
        notes = results[0] as List<dynamic>;
        history = results[1] as List<dynamic>;
        progress = results[2] as Map<String, dynamic>;
        subscription = results[3] as Map<String, dynamic>;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final average =
        progress?['average_score'] as int? ?? _averageScore(history);
    final streak = progress?['streak_days'] as int? ?? 0;
    final studyMinutes =
        ((progress?['study_seconds'] as int? ?? 0) / 60).round();
    final plan = subscription?['plan']?.toString() ?? 'free';
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            BrandMark(size: 34),
            SizedBox(width: 10),
            Text('ExamAI'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const Padding(
              padding: EdgeInsets.only(right: 8), child: ThemeToggle()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => UploadScreen(api: widget.api, userId: userId)),
          );
          refresh();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New note'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex,
        onDestinationSelected: (value) => setState(() => navIndex = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.library_books_rounded), label: 'Library'),
          NavigationDestination(
              icon: Icon(Icons.quiz_rounded), label: 'Practice'),
          NavigationDestination(
              icon: Icon(Icons.insights_rounded), label: 'Progress'),
          NavigationDestination(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding:
              EdgeInsets.fromLTRB(compact ? 16 : 28, 10, compact ? 16 : 28, 96),
          children: _dashboardSections(
            theme: theme,
            average: average,
            streak: streak,
            studyMinutes: studyMinutes,
            plan: plan,
            compact: compact,
          ),
        ),
      ),
    );
  }

  List<Widget> _dashboardSections({
    required ThemeData theme,
    required int? average,
    required int streak,
    required int studyMinutes,
    required String plan,
    required bool compact,
  }) {
    final header = [
      _DashboardHeader(
          user: widget.user,
          noteCount: notes.length,
          averageScore: average,
          plan: plan),
      const SizedBox(height: 18),
      TodayFocusCard(
        note: notes.isEmpty ? null : notes.first as Map<String, dynamic>,
        weakTopics: (progress?['weak_topics'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        onContinue: notes.isEmpty
            ? null
            : () async {
                final note = notes.first as Map<String, dynamic>;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => StudyScreen(
                          api: widget.api, userId: userId, note: note)),
                );
                refresh();
              },
      ),
      const SizedBox(height: 18),
      StudyPlannerPanel(
        api: widget.api,
        userId: userId,
        note: notes.isEmpty ? null : notes.first as Map<String, dynamic>,
      ),
      const SizedBox(height: 18),
      PlanBanner(
        subscription: subscription,
        onToggle: () async {
          final next = plan == 'premium' ? 'free' : 'premium';
          try {
            if (next == 'premium') {
              final checkout = await widget.api.createCheckout(userId, next);
              if (mounted) {
                showMessage(
                    context,
                    checkout['message']?.toString() ??
                        'Premium checkout ready.');
              }
            }
            await widget.api.updateSubscription(userId, next);
            await refresh();
          } catch (error) {
            if (!mounted) return;
            showMessage(context, error.toString());
          }
        },
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 980
              ? 5
              : constraints.maxWidth > 720
                  ? 3
                  : constraints.maxWidth > 560
                      ? 2
                      : 1;
          return ResponsiveGrid(
            columns: columns,
            spacing: 12,
            children: [
              StatTile(
                  icon: Icons.library_books_rounded,
                  label: 'Notes',
                  value: '${notes.length}',
                  color: AppTheme.teal),
              StatTile(
                  icon: Icons.task_alt_rounded,
                  label: 'Quizzes',
                  value: '${history.length}',
                  color: AppTheme.coral),
              StatTile(
                  icon: Icons.speed_rounded,
                  label: 'Average',
                  value: average == null ? '--' : '$average%',
                  color: AppTheme.amber),
              StatTile(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Streak',
                  value: '$streak day',
                  color: const Color(0xff7c5cff)),
              StatTile(
                  icon: Icons.timer_rounded,
                  label: 'Study Time',
                  value: '${studyMinutes}m',
                  color: const Color(0xff2899d8)),
            ],
          );
        },
      ),
    ];

    final library = [
      SectionHeader(
        title: 'Study Library',
        action: TextButton.icon(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      UploadScreen(api: widget.api, userId: userId)),
            );
            refresh();
          },
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Upload'),
        ),
      ),
      const SizedBox(height: 12),
      if (loading)
        const LoadingPanel(label: 'Loading your study space...')
      else if (notes.isEmpty)
        EmptyLibrary(onUpload: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => UploadScreen(api: widget.api, userId: userId)),
          );
          refresh();
        })
      else
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 980
                ? 3
                : constraints.maxWidth > 640
                    ? 2
                    : 1;
            return ResponsiveGrid(
              columns: columns,
              spacing: 12,
              children: [
                for (final note in notes)
                  NoteTile(
                    note: note as Map<String, dynamic>,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudyScreen(
                              api: widget.api, userId: userId, note: note),
                        ),
                      );
                      refresh();
                    },
                  ),
              ],
            );
          },
        ),
    ];

    final practice = [
      const SectionHeader(title: 'Practice'),
      const SizedBox(height: 12),
      if (history.isEmpty)
        EmptyActionPanel(
          icon: Icons.quiz_rounded,
          title: 'No quiz scores yet',
          message: 'Open a note, generate MCQs, and start a quiz.',
          buttonLabel: 'Open library',
          onPressed: () => setState(() => navIndex = 1),
        )
      else
        for (final item in history.take(10))
          QuizHistoryTile(item: item as Map<String, dynamic>),
    ];

    final progressSection = [
      if ((progress?['weak_topics'] as List<dynamic>? ?? []).isNotEmpty ||
          (progress?['strong_topics'] as List<dynamic>? ?? []).isNotEmpty)
        TopicProgressPanel(progress: progress!)
      else
        EmptyActionPanel(
          icon: Icons.insights_rounded,
          title: 'Progress will grow here',
          message: 'Complete quizzes to reveal strong and weak topics.',
          buttonLabel: 'Practice',
          onPressed: () => setState(() => navIndex = 2),
        ),
    ];

    final profile = [
      ProfilePanel(
          user: widget.user,
          subscription: subscription,
          apiBase: widget.api.baseUrl,
          api: widget.api,
          userId: userId),
    ];

    return switch (navIndex) {
      0 => [
          ...header,
          if ((progress?['weak_topics'] as List<dynamic>? ?? []).isNotEmpty ||
              (progress?['strong_topics'] as List<dynamic>? ?? [])
                  .isNotEmpty) ...[
            const SizedBox(height: 24),
            TopicProgressPanel(progress: progress!),
          ],
          const SizedBox(height: 24),
          ...library.take(3),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Recent Scores', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final item in history.take(3))
              QuizHistoryTile(item: item as Map<String, dynamic>),
          ],
        ],
      1 => library,
      2 => practice,
      3 => progressSection,
      _ => profile,
    };
  }

  int? _averageScore(List<dynamic> rows) {
    if (rows.isEmpty) return null;
    final scores = rows
        .map((row) => row as Map<String, dynamic>)
        .where((row) =>
            (row['total_questions'] as num?) != null &&
            (row['total_questions'] as num) > 0)
        .map((row) =>
            ((row['score'] as num) / (row['total_questions'] as num)) * 100)
        .toList();
    if (scores.isEmpty) return null;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.user,
    required this.noteCount,
    required this.averageScore,
    required this.plan,
  });

  final Map<String, dynamic> user;
  final int noteCount;
  final int? averageScore;
  final String plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = user['full_name']?.toString().split(' ').first ?? 'Student';
    return SurfacePanel(
      color: theme.colorScheme.primaryContainer
          .withValues(alpha: theme.brightness == Brightness.dark ? 0.25 : 0.78),
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, $name', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                noteCount == 0
                    ? 'Add a note and start your first revision sprint.'
                    : 'Your next study session is ready when you are.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  const FeaturePill(
                      icon: Icons.psychology_alt_rounded,
                      label: 'AI study mode'),
                  const FeaturePill(
                      icon: Icons.timer_rounded, label: 'Quick practice'),
                  FeaturePill(
                      icon: Icons.workspace_premium_rounded,
                      label: plan == 'premium' ? 'Premium' : 'Free plan'),
                  FeaturePill(
                      icon: Icons.workspace_premium_rounded,
                      label: averageScore == null
                          ? 'Fresh start'
                          : '$averageScore% average'),
                ],
              ),
            ],
          );
          final badge = ProgressBadge(
              percent: averageScore ?? 0,
              label: averageScore == null ? 'Ready' : '$averageScore%');
          if (compact) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [left, const SizedBox(height: 18), badge]);
          }
          return Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 20),
              badge,
            ],
          );
        },
      ),
    );
  }
}

class TodayFocusCard extends StatelessWidget {
  const TodayFocusCard(
      {super.key,
      required this.note,
      required this.weakTopics,
      required this.onContinue});

  final Map<String, dynamic>? note;
  final List<String> weakTopics;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNote = note != null;
    return SurfacePanel(
      color: theme.colorScheme.primaryContainer
          .withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.5),
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.today_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text("Today's Focus", style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hasNote
                    ? note!['title']?.toString() ?? 'Continue studying'
                    : 'Start your first study sprint',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                hasNote
                    ? 'Continue with your latest material, then review weak topics.'
                    : 'Upload notes and ExamAI will build summaries, MCQs, flashcards, and quiz practice.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (weakTopics.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: weakTopics
                      .take(4)
                      .map((topic) => FeaturePill(
                          icon: Icons.healing_rounded, label: topic))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(hasNote ? 'Continue studying' : 'Upload a note'),
              ),
            ],
          );
          final ring = ProgressBadge(
              percent: hasNote ? 68 : 0, label: hasNote ? 'Focus' : 'New');
          if (compact) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [content, const SizedBox(height: 16), ring]);
          }
          return Row(children: [
            Expanded(child: content),
            const SizedBox(width: 18),
            ring
          ]);
        },
      ),
    );
  }
}

class StudyPlannerPanel extends StatefulWidget {
  const StudyPlannerPanel(
      {super.key, required this.api, required this.userId, required this.note});

  final ApiClient api;
  final int userId;
  final Map<String, dynamic>? note;

  @override
  State<StudyPlannerPanel> createState() => _StudyPlannerPanelState();
}

class _StudyPlannerPanelState extends State<StudyPlannerPanel> {
  final goalController = TextEditingController(text: 'Prepare for exam');
  final examDateController = TextEditingController();
  int dailyMinutes = 45;
  List<dynamic> plan = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final target = DateTime.now().add(const Duration(days: 21));
    examDateController.text =
        '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    goalController.dispose();
    examDateController.dispose();
    super.dispose();
  }

  Future<void> create() async {
    setState(() => loading = true);
    try {
      final result = await widget.api.createStudyPlan(
        widget.userId,
        widget.note?['id'] as int?,
        examDateController.text.trim(),
        dailyMinutes,
        goalController.text.trim().isEmpty
            ? 'Prepare for exam'
            : goalController.text.trim(),
      );
      if (!mounted) return;
      setState(() => plan = result['plan'] as List<dynamic>? ?? []);
      showMessage(context, 'Study planner created.');
    } catch (error) {
      if (mounted) showMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfacePanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Study Planner',
            action: FilledButton.icon(
              onPressed: loading ? null : create,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.event_available_rounded),
              label: const Text('Create plan'),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 210,
                child: TextField(
                  controller: examDateController,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.event_rounded),
                      labelText: 'Exam date'),
                ),
              ),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: goalController,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.flag_rounded),
                      labelText: 'Study goal'),
                ),
              ),
              SizedBox(
                width: 260,
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('$dailyMinutes min/day',
                            style: theme.textTheme.titleMedium)),
                    Expanded(
                      child: Slider(
                        min: 15,
                        max: 180,
                        divisions: 11,
                        value: dailyMinutes.toDouble(),
                        onChanged: (value) =>
                            setState(() => dailyMinutes = value.round()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (plan.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final item in plan.take(4).cast<Map<String, dynamic>>())
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SurfacePanel(
                  padding: const EdgeInsets.all(12),
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      CircleAvatar(child: Text('${item['day'] ?? ''}')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${item['focus'] ?? 'Revision'} - ${item['task'] ?? 'Study and practice'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class ProfilePanel extends StatefulWidget {
  const ProfilePanel({
    super.key,
    required this.user,
    required this.subscription,
    required this.apiBase,
    required this.api,
    required this.userId,
  });

  final Map<String, dynamic> user;
  final Map<String, dynamic>? subscription;
  final String apiBase;
  final ApiClient api;
  final int userId;

  @override
  State<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<ProfilePanel> {
  final levelController = TextEditingController();
  final subjectController = TextEditingController();
  final examTypeController = TextEditingController();
  final goalController = TextEditingController();
  final reminderController = TextEditingController();
  String aiTone = 'Step-by-step';
  final classNameController = TextEditingController(text: 'ExamAI Class');
  List<Map<String, dynamic>> classes = [];
  bool savingPrefs = false;
  bool creatingClass = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    levelController.dispose();
    subjectController.dispose();
    examTypeController.dispose();
    goalController.dispose();
    reminderController.dispose();
    classNameController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        widget.api.preferences(widget.userId),
        widget.api.teacherClasses(widget.userId),
      ]);
      if (!mounted) return;
      final prefs = results[0] as Map<String, dynamic>;
      setState(() {
        levelController.text =
            prefs['academic_level']?.toString() ?? 'University';
        subjectController.text = prefs['subject']?.toString() ?? 'General';
        examTypeController.text =
            prefs['exam_type']?.toString() ?? 'Course exam';
        goalController.text =
            prefs['study_goal']?.toString() ?? 'Pass with confidence';
        reminderController.text =
            prefs['daily_reminder']?.toString() ?? '18:00';
        aiTone = prefs['ai_tone']?.toString() ?? 'Step-by-step';
        classes = (results[1] as List<dynamic>).cast<Map<String, dynamic>>();
      });
    } catch (_) {
      levelController.text = 'University';
      subjectController.text = 'General';
      examTypeController.text = 'Course exam';
      goalController.text = 'Pass with confidence';
      reminderController.text = '18:00';
    }
  }

  Future<void> savePrefs() async {
    setState(() => savingPrefs = true);
    try {
      await widget.api.savePreferences(widget.userId, {
        'academic_level': levelController.text.trim(),
        'subject': subjectController.text.trim(),
        'exam_type': examTypeController.text.trim(),
        'study_goal': goalController.text.trim(),
        'daily_reminder': reminderController.text.trim(),
        'ai_tone': aiTone,
      });
      if (mounted) showMessage(context, 'Preferences saved.');
    } catch (error) {
      if (mounted) showMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => savingPrefs = false);
    }
  }

  Future<void> createClass() async {
    if (classNameController.text.trim().isEmpty) return;
    setState(() => creatingClass = true);
    try {
      final created = await widget.api
          .createClass(widget.userId, classNameController.text.trim());
      if (!mounted) return;
      setState(() => classes.insert(0, created));
      showMessage(context, 'Class created. Join code: ${created['join_code']}');
    } catch (error) {
      if (mounted) showMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => creatingClass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = widget.subscription?['plan']?.toString() ?? 'free';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfacePanel(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BrandMark(size: 58),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.user['full_name']?.toString() ?? 'Student',
                            style: theme.textTheme.headlineSmall),
                        Text(widget.user['email']?.toString() ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FeaturePill(
                      icon: Icons.workspace_premium_rounded,
                      label: plan == 'premium' ? 'Premium' : 'Free'),
                  FeaturePill(
                      icon: Icons.cloud_queue_rounded, label: widget.apiBase),
                  const FeaturePill(
                      icon: Icons.phone_iphone_rounded,
                      label: 'Android, iOS, Windows'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SurfacePanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Personalization',
                action: FilledButton.icon(
                  onPressed: savingPrefs ? null : savePrefs,
                  icon: savingPrefs
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                      width: 210,
                      child: TextField(
                          controller: levelController,
                          decoration: const InputDecoration(
                              labelText: 'Academic level'))),
                  SizedBox(
                      width: 210,
                      child: TextField(
                          controller: subjectController,
                          decoration:
                              const InputDecoration(labelText: 'Subject'))),
                  SizedBox(
                      width: 210,
                      child: TextField(
                          controller: examTypeController,
                          decoration:
                              const InputDecoration(labelText: 'Exam type'))),
                  SizedBox(
                      width: 250,
                      child: TextField(
                          controller: goalController,
                          decoration:
                              const InputDecoration(labelText: 'Study goal'))),
                  SizedBox(
                      width: 160,
                      child: TextField(
                          controller: reminderController,
                          decoration:
                              const InputDecoration(labelText: 'Reminder'))),
                  DropdownMenu<String>(
                    width: 220,
                    label: const Text('AI tutor tone'),
                    initialSelection: aiTone,
                    onSelected: (value) {
                      if (value != null) setState(() => aiTone = value);
                    },
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(
                          value: 'Step-by-step', label: 'Step-by-step'),
                      DropdownMenuEntry(
                          value: 'Explain like I am 10',
                          label: 'Explain like I am 10'),
                      DropdownMenuEntry(
                          value: 'University level', label: 'University level'),
                      DropdownMenuEntry(
                          value: 'Example-based', label: 'Example-based'),
                      DropdownMenuEntry(
                          value: 'Socratic questioning',
                          label: 'Socratic questioning'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SurfacePanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Teacher Mode',
                action: FilledButton.icon(
                  onPressed: creatingClass ? null : createClass,
                  icon: creatingClass
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.groups_rounded),
                  label: const Text('Create class'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: classNameController,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.class_rounded),
                    labelText: 'Class name'),
              ),
              if (classes.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final row in classes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.school_rounded),
                    title: Text(row['name']?.toString() ?? 'Class'),
                    subtitle: Text('Join code: ${row['join_code'] ?? ''}'),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class PlanBanner extends StatelessWidget {
  const PlanBanner(
      {super.key, required this.subscription, required this.onToggle});

  final Map<String, dynamic>? subscription;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = subscription?['plan']?.toString() ?? 'free';
    final uploads = subscription?['uploads_used'] as int? ?? 0;
    final limit = subscription?['upload_limit'];
    final premium = plan == 'premium';
    return SurfacePanel(
      color: premium
          ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.72)
          : theme.colorScheme.secondaryContainer.withValues(alpha: 0.48),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
              premium
                  ? Icons.workspace_premium_rounded
                  : Icons.lock_open_rounded,
              size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(premium ? 'Premium plan active' : 'Free plan',
                    style: theme.textTheme.titleMedium),
                Text(
                  premium
                      ? 'Unlimited uploads, mock exams, and advanced explanations.'
                      : '$uploads/${limit ?? 3} uploads used this month.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onToggle,
            icon: Icon(premium ? Icons.undo_rounded : Icons.upgrade_rounded),
            label: Text(premium ? 'Use free' : 'Upgrade'),
          ),
        ],
      ),
    );
  }
}

class TopicProgressPanel extends StatelessWidget {
  const TopicProgressPanel({super.key, required this.progress});

  final Map<String, dynamic> progress;

  @override
  Widget build(BuildContext context) {
    final weak = (progress['weak_topics'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final strong = (progress['strong_topics'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final panels = [
          TopicList(
              title: 'Weak Topics',
              icon: Icons.healing_rounded,
              topics: weak,
              color: AppTheme.coral),
          TopicList(
              title: 'Strong Topics',
              icon: Icons.trending_up_rounded,
              topics: strong,
              color: AppTheme.teal),
        ];
        if (constraints.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: panels[0]),
              const SizedBox(width: 12),
              Expanded(child: panels[1]),
            ],
          );
        }
        return Column(
            children: [panels[0], const SizedBox(height: 12), panels[1]]);
      },
    );
  }
}

class TopicList extends StatelessWidget {
  const TopicList(
      {super.key,
      required this.title,
      required this.icon,
      required this.topics,
      required this.color});

  final String title;
  final IconData icon;
  final List<String> topics;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          if (topics.isEmpty)
            Text('Take a quiz to unlock this insight.',
                style: Theme.of(context).textTheme.bodyMedium)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final topic in topics)
                  FeaturePill(icon: Icons.circle_rounded, label: topic)
              ],
            ),
        ],
      ),
    );
  }
}

class StudySettingsPanel extends StatelessWidget {
  const StudySettingsPanel({
    super.key,
    required this.summaryMode,
    required this.quizDifficulty,
    required this.quizMode,
    required this.questionCount,
    required this.onSummaryMode,
    required this.onQuizDifficulty,
    required this.onQuizMode,
    required this.onQuestionCount,
  });

  final String summaryMode;
  final String quizDifficulty;
  final String quizMode;
  final int questionCount;
  final ValueChanged<String> onSummaryMode;
  final ValueChanged<String> onQuizDifficulty;
  final ValueChanged<String> onQuizMode;
  final ValueChanged<int> onQuestionCount;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      padding: const EdgeInsets.all(14),
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Study Controls',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DropdownMenu<String>(
                width: 210,
                label: const Text('AI mode'),
                initialSelection: summaryMode,
                onSelected: (value) {
                  if (value != null) onSummaryMode(value);
                },
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'short', label: 'Short summary'),
                  DropdownMenuEntry(
                      value: 'detailed', label: 'Detailed summary'),
                  DropdownMenuEntry(value: 'exam', label: 'Exam focus'),
                  DropdownMenuEntry(
                      value: 'definitions', label: 'Key definitions'),
                  DropdownMenuEntry(
                      value: 'likely_questions', label: 'Likely questions'),
                  DropdownMenuEntry(
                      value: 'weak_topics', label: 'Weak-topic help'),
                ],
              ),
              DropdownMenu<String>(
                width: 170,
                label: const Text('Difficulty'),
                initialSelection: quizDifficulty,
                onSelected: (value) {
                  if (value != null) onQuizDifficulty(value);
                },
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'easy', label: 'Easy'),
                  DropdownMenuEntry(value: 'medium', label: 'Medium'),
                  DropdownMenuEntry(value: 'hard', label: 'Hard'),
                  DropdownMenuEntry(value: 'mixed', label: 'Mixed'),
                ],
              ),
              DropdownMenu<String>(
                width: 170,
                label: const Text('Quiz mode'),
                initialSelection: quizMode,
                onSelected: (value) {
                  if (value != null) onQuizMode(value);
                },
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'practice', label: 'Practice'),
                  DropdownMenuEntry(value: 'random', label: 'Random'),
                  DropdownMenuEntry(value: 'mock', label: 'Mock exam'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.format_list_numbered_rounded),
              const SizedBox(width: 8),
              Expanded(child: Text('Questions: $questionCount')),
              SizedBox(
                width: 220,
                child: Slider(
                  min: 3,
                  max: 25,
                  divisions: 22,
                  value: questionCount.toDouble(),
                  label: '$questionCount',
                  onChanged: (value) => onQuestionCount(value.round()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, required this.api, required this.userId});

  final ApiClient api;
  final int userId;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final titleController = TextEditingController();
  final textController = TextEditingController();
  PlatformFile? selectedFile;
  bool loading = false;

  bool get canSave {
    return titleController.text.trim().isNotEmpty &&
        (selectedFile != null || textController.text.trim().isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    titleController.addListener(() => setState(() {}));
    textController.addListener(() => setState(() {}));
  }

  Future<void> save() async {
    if (!canSave) {
      showMessage(
          context, 'Add a title and either pick a file or paste notes.');
      return;
    }
    setState(() => loading = true);
    try {
      if (selectedFile != null) {
        await widget.api
            .uploadFile(widget.userId, titleController.text, selectedFile!);
      } else {
        await widget.api.createTextNote(
            widget.userId, titleController.text, textController.text);
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) showMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Study Material')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          SurfacePanel(
            color: theme.colorScheme.secondaryContainer.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.22 : 0.7),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.auto_stories_rounded,
                    size: 42, color: theme.colorScheme.secondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Drop in lecture notes, PDF handouts, or pasted text. ExamAI will turn it into practice material.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.title_rounded), labelText: 'Title'),
          ),
          const SizedBox(height: 14),
          FileDropPanel(
            selectedFile: selectedFile,
            onPick: () async {
              final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom, allowedExtensions: ['pdf', 'txt']);
              if (result != null) {
                setState(() => selectedFile = result.files.single);
              }
            },
            onClear: selectedFile == null
                ? null
                : () => setState(() => selectedFile = null),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: textController,
            minLines: 10,
            maxLines: 16,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.notes_rounded),
              labelText: 'Paste notes',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: loading ? null : save,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_upload_rounded),
            label: Text(loading ? 'Saving material...' : 'Save material'),
          ),
        ),
      ),
    );
  }
}

class StudyScreen extends StatefulWidget {
  const StudyScreen(
      {super.key, required this.api, required this.userId, required this.note});

  final ApiClient api;
  final int userId;
  final Map<String, dynamic> note;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  String summary = '';
  List<Map<String, dynamic>> questions = [];
  List<Map<String, dynamic>> flashcards = [];
  Map<String, dynamic>? prediction;
  bool loadingSummary = false;
  bool loadingQuestions = false;
  bool loadingCards = false;
  bool loadingPrediction = false;
  int selectedTab = 0;
  String summaryMode = 'short';
  String quizDifficulty = 'medium';
  String quizMode = 'practice';
  int questionCount = 8;

  int get noteId => widget.note['id'] as int;

  Future<void> summarize() async {
    setState(() {
      selectedTab = 0;
      loadingSummary = true;
    });
    try {
      final result =
          await widget.api.summarize(widget.userId, noteId, summaryMode);
      if (!mounted) return;
      setState(() => summary = result['summary_text']?.toString() ?? '');
    } catch (error) {
      if (mounted) showMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => loadingSummary = false);
    }
  }

  Future<void> generateMcq() async {
    setState(() {
      selectedTab = 2;
      loadingQuestions = true;
    });
    try {
      final result = await widget.api
          .generateMcq(noteId, quizDifficulty, quizMode, questionCount);
      if (!mounted) return;
      final raw = (result['questions'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() => questions = raw.map(normalizeQuestion).toList());
    } catch (error) {
      if (mounted) showMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => loadingQuestions = false);
    }
  }

  Future<void> generateFlashcards() async {
    setState(() {
      selectedTab = 3;
      loadingCards = true;
    });
    try {
      final result = await widget.api.generateFlashcards(noteId);
      if (!mounted) return;
      final raw = (result['flashcards'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() => flashcards = raw);
    } catch (error) {
      if (mounted) showMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => loadingCards = false);
    }
  }

  Future<void> predictExam() async {
    setState(() {
      selectedTab = 4;
      loadingPrediction = true;
    });
    try {
      final result = await widget.api.examPrediction(noteId);
      if (!mounted) return;
      setState(() => prediction = result);
    } catch (error) {
      if (mounted) showMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => loadingPrediction = false);
    }
  }

  Future<void> startQuiz() async {
    try {
      final data = questions.isEmpty
          ? (await widget.api
                  .startQuiz(noteId, quizMode, quizDifficulty, questionCount))
              .cast<Map<String, dynamic>>()
              .map(normalizeQuestion)
              .toList()
          : questions;
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            api: widget.api,
            userId: widget.userId,
            noteId: noteId,
            questions: data,
            mode: quizMode,
            difficulty: quizDifficulty,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      showMessage(context, 'Generate MCQs first, then start the quiz.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note['title']?.toString() ?? 'Study Material'),
        actions: [
          IconButton(
              tooltip: 'Copy title',
              onPressed: () => Clipboard.setData(
                  ClipboardData(text: widget.note['title'].toString())),
              icon: const Icon(Icons.copy_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
        children: [
          SurfacePanel(
            padding: const EdgeInsets.all(18),
            color: theme.colorScheme.tertiaryContainer.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.2 : 0.66),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Study Workspace', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Generate exactly what you need for this note, then jump straight into practice.',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ActionChipButton(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Summary',
                      loading: loadingSummary,
                      onPressed: summarize,
                    ),
                    ActionChipButton(
                      icon: Icons.quiz_rounded,
                      label: 'MCQs',
                      loading: loadingQuestions,
                      onPressed: generateMcq,
                    ),
                    ActionChipButton(
                      icon: Icons.style_rounded,
                      label: 'Flashcards',
                      loading: loadingCards,
                      onPressed: generateFlashcards,
                    ),
                    ActionChipButton(
                      icon: Icons.radar_rounded,
                      label: 'Predict exam',
                      loading: loadingPrediction,
                      onPressed: predictExam,
                    ),
                    ActionChipButton(
                      icon: Icons.play_circle_fill_rounded,
                      label: 'Start quiz',
                      onPressed: startQuiz,
                    ),
                    ActionChipButton(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Chat',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NoteChatScreen(
                              api: widget.api,
                              userId: widget.userId,
                              noteId: noteId),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StudySettingsPanel(
                  summaryMode: summaryMode,
                  quizDifficulty: quizDifficulty,
                  quizMode: quizMode,
                  questionCount: questionCount,
                  onSummaryMode: (value) => setState(() => summaryMode = value),
                  onQuizDifficulty: (value) =>
                      setState(() => quizDifficulty = value),
                  onQuizMode: (value) => setState(() => quizMode = value),
                  onQuestionCount: (value) =>
                      setState(() => questionCount = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StudyModeTabs(
            selected: selectedTab,
            onSelected: (value) => setState(() => selectedTab = value),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: switch (selectedTab) {
              0 => SummaryView(
                  key: const ValueKey('summary'),
                  summary: summary,
                  loading: loadingSummary,
                  onGenerate: summarize),
              1 => InlineChatView(
                  key: const ValueKey('chat'),
                  api: widget.api,
                  userId: widget.userId,
                  noteId: noteId),
              2 => McqView(
                  key: const ValueKey('mcqs'),
                  questions: questions,
                  loading: loadingQuestions,
                  onGenerate: generateMcq,
                  onQuiz: startQuiz),
              3 => FlashcardView(
                  key: const ValueKey('cards'),
                  api: widget.api,
                  cards: flashcards,
                  loading: loadingCards,
                  onGenerate: generateFlashcards,
                ),
              4 => ExamPredictionView(
                  key: const ValueKey('prediction'),
                  prediction: prediction,
                  loading: loadingPrediction,
                  onGenerate: predictExam,
                ),
              _ => NoteProgressView(
                  key: const ValueKey('note-progress'), note: widget.note),
            },
          ),
        ],
      ),
    );
  }
}

class StudyModeTabs extends StatelessWidget {
  const StudyModeTabs(
      {super.key, required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  static const tabs = [
    (Icons.subject_rounded, 'Summary', AppTheme.teal),
    (Icons.chat_bubble_rounded, 'Chat', Color(0xff2899d8)),
    (Icons.checklist_rounded, 'MCQ', AppTheme.coral),
    (Icons.style_rounded, 'Cards', AppTheme.amber),
    (Icons.radar_rounded, 'Predict', Color(0xff1d7a57)),
    (Icons.insights_rounded, 'Progress', Color(0xff7c5cff)),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(tabs[i].$1,
                    size: 18, color: selected == i ? Colors.white : tabs[i].$3),
                label: Text(tabs[i].$2),
                selected: selected == i,
                selectedColor: tabs[i].$3,
                labelStyle: TextStyle(
                    color: selected == i ? Colors.white : null,
                    fontWeight: FontWeight.w700),
                onSelected: (_) => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class SummaryView extends StatelessWidget {
  const SummaryView(
      {super.key,
      required this.summary,
      required this.loading,
      required this.onGenerate});

  final String summary;
  final bool loading;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const LoadingPanel(label: 'Writing your study summary...');
    }
    if (summary.isEmpty) {
      return EmptyActionPanel(
        icon: Icons.auto_awesome_rounded,
        title: 'No summary yet',
        message:
            'Generate one when you want the note compressed into revision points.',
        buttonLabel: 'Generate summary',
        onPressed: onGenerate,
      );
    }
    return SurfacePanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Smart Summary',
            action: IconButton(
              tooltip: 'Copy summary',
              onPressed: () => Clipboard.setData(ClipboardData(text: summary)),
              icon: const Icon(Icons.copy_rounded),
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(summary,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}

class McqView extends StatelessWidget {
  const McqView({
    super.key,
    required this.questions,
    required this.loading,
    required this.onGenerate,
    required this.onQuiz,
  });

  final List<Map<String, dynamic>> questions;
  final bool loading;
  final VoidCallback onGenerate;
  final VoidCallback onQuiz;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const LoadingPanel(label: 'Generating exam-style questions...');
    }
    if (questions.isEmpty) {
      return EmptyActionPanel(
        icon: Icons.quiz_rounded,
        title: 'No MCQs yet',
        message: 'Create practice questions and test yourself right away.',
        buttonLabel: 'Generate MCQs',
        onPressed: onGenerate,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '${questions.length} Practice Questions',
          action: FilledButton.icon(
              onPressed: onQuiz,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Quiz')),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < questions.length; index++)
          McqPreview(index: index, item: questions[index]),
      ],
    );
  }
}

class FlashcardView extends StatefulWidget {
  const FlashcardView({
    super.key,
    required this.api,
    required this.cards,
    required this.loading,
    required this.onGenerate,
  });

  final ApiClient api;
  final List<Map<String, dynamic>> cards;
  final bool loading;
  final VoidCallback onGenerate;

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  int index = 0;
  bool flipped = false;

  @override
  void didUpdateWidget(covariant FlashcardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cards.length != widget.cards.length) {
      index = 0;
      flipped = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const LoadingPanel(label: 'Making flashcards...');
    }
    if (widget.cards.isEmpty) {
      return EmptyActionPanel(
        icon: Icons.style_rounded,
        title: 'No flashcards yet',
        message: 'Turn key concepts into quick cards for active recall.',
        buttonLabel: 'Generate flashcards',
        onPressed: widget.onGenerate,
      );
    }
    final card = widget.cards[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Card ${index + 1} of ${widget.cards.length}',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => flipped = !flipped),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(minHeight: 220),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: flipped
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  flipped
                      ? card['back_text']?.toString() ?? ''
                      : card['front_text']?.toString() ?? '',
                  key: ValueKey(flipped),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => rate('hard'),
                icon: const Icon(Icons.priority_high_rounded),
                label: const Text('Hard'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => rate('medium'),
                icon: const Icon(Icons.drag_handle_rounded),
                label: const Text('Medium'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => rate('easy'),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Easy'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: index == 0
                    ? null
                    : () => setState(() {
                          index--;
                          flipped = false;
                        }),
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: index == widget.cards.length - 1
                    ? null
                    : () => setState(() {
                          index++;
                          flipped = false;
                        }),
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> rate(String rating) async {
    final card = widget.cards[index];
    final id = card['id'] as int?;
    if (id != null) {
      try {
        await widget.api.rateFlashcard(id, rating);
      } catch (_) {
        // The local interaction still advances even if persistence fails.
      }
    }
    if (!mounted) return;
    HapticFeedback.selectionClick();
    if (index < widget.cards.length - 1) {
      setState(() {
        index++;
        flipped = false;
      });
    } else {
      showMessage(context, 'Nice. Card marked $rating.');
    }
  }
}

class NoteChatScreen extends StatefulWidget {
  const NoteChatScreen(
      {super.key,
      required this.api,
      required this.userId,
      required this.noteId});

  final ApiClient api;
  final int userId;
  final int noteId;

  @override
  State<NoteChatScreen> createState() => _NoteChatScreenState();
}

class _NoteChatScreenState extends State<NoteChatScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final rows = await widget.api.chatHistory(widget.userId, widget.noteId);
      if (!mounted) return;
      setState(() {
        messages = rows.cast<Map<String, dynamic>>();
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> send([String? prompt]) async {
    final text = (prompt ?? controller.text).trim();
    if (text.isEmpty || sending) return;
    controller.clear();
    setState(() {
      sending = true;
      messages.add({'role': 'user', 'message': text});
    });
    try {
      final result =
          await widget.api.chatWithNote(widget.userId, widget.noteId, text);
      if (!mounted) return;
      setState(() => messages.add({
            'role': 'assistant',
            'message': result['answer']?.toString() ?? ''
          }));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    } catch (error) {
      if (mounted) showMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat With Notes')),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              children: [
                PromptChip(
                    label: 'Explain topic 3',
                    onTap: () => send('Explain topic 3')),
                PromptChip(
                    label: 'Likely exam questions',
                    onTap: () => send('Give me likely exam questions')),
                PromptChip(
                    label: 'Teach me like I am new',
                    onTap: () => send('Teach me this like I am new')),
                PromptChip(
                    label: 'Find my weak topics',
                    onTap: () => send('Find my weak topics')),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                        ? const EmptyActionPanel(
                            icon: Icons.chat_bubble_rounded,
                            title: 'Ask your note anything',
                            message:
                                'Use a prompt above or type your own question.',
                            buttonLabel: 'Try a prompt',
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) =>
                                ChatBubble(message: messages[index]),
                          ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => send(),
                          decoration: const InputDecoration(
                            hintText:
                                'Ask for explanations, examples, or likely questions',
                            prefixIcon: Icon(Icons.psychology_alt_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Send',
                        onPressed: sending ? null : send,
                        icon: sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InlineChatView extends StatefulWidget {
  const InlineChatView(
      {super.key,
      required this.api,
      required this.userId,
      required this.noteId});

  final ApiClient api;
  final int userId;
  final int noteId;

  @override
  State<InlineChatView> createState() => _InlineChatViewState();
}

class _InlineChatViewState extends State<InlineChatView> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final rows = await widget.api.chatHistory(widget.userId, widget.noteId);
      if (!mounted) return;
      setState(() {
        messages = rows.cast<Map<String, dynamic>>();
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> send([String? prompt]) async {
    final text = (prompt ?? controller.text).trim();
    if (text.isEmpty || sending) return;
    controller.clear();
    setState(() {
      sending = true;
      messages.add({'role': 'user', 'message': text});
    });
    try {
      final result =
          await widget.api.chatWithNote(widget.userId, widget.noteId, text);
      if (!mounted) return;
      setState(() => messages.add({
            'role': 'assistant',
            'message': result['answer']?.toString() ?? ''
          }));
    } catch (error) {
      if (mounted) showMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingPanel(label: 'Loading note chat...');
    return SurfacePanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Chat With This Note',
            action: IconButton(
              tooltip: 'Clear draft',
              onPressed: () => controller.clear(),
              icon: const Icon(Icons.cleaning_services_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PromptChip(
                  label: 'Explain this simply',
                  onTap: () => send('Explain this like I am new')),
              PromptChip(
                  label: 'Give examples',
                  onTap: () =>
                      send('Generate practical examples from this note')),
              PromptChip(
                  label: 'Likely exam questions',
                  onTap: () =>
                      send('Give me likely exam questions with answers')),
              PromptChip(
                  label: 'Socratic tutor',
                  onTap: () => send('Tutor me using Socratic questioning')),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 260, maxHeight: 520),
            child: messages.isEmpty
                ? const EmptyActionPanel(
                    icon: Icons.chat_bubble_rounded,
                    title: 'Ask your notes anything',
                    message:
                        'Get explanations, examples, citations, and follow-up questions from the material.',
                    buttonLabel: 'Try a prompt',
                  )
                : ListView.builder(
                    controller: scrollController,
                    shrinkWrap: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) =>
                        ChatBubble(message: messages[index]),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => send(),
                  decoration: const InputDecoration(
                    hintText:
                        'Ask for a simpler explanation, source paragraph, or likely question',
                    prefixIcon: Icon(Icons.psychology_alt_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send',
                onPressed: sending ? null : send,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ExamPredictionView extends StatelessWidget {
  const ExamPredictionView(
      {super.key,
      required this.prediction,
      required this.loading,
      required this.onGenerate});

  final Map<String, dynamic>? prediction;
  final bool loading;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const LoadingPanel(label: 'Predicting likely exam focus...');
    }
    if (prediction == null) {
      return EmptyActionPanel(
        icon: Icons.radar_rounded,
        title: 'No exam prediction yet',
        message:
            'Let ExamAI rank likely topics, theory questions, MCQs, and high-priority concepts.',
        buttonLabel: 'Predict exam',
        onPressed: onGenerate,
      );
    }
    final groups = [
      ('Likely Topics', Icons.topic_rounded, prediction!['likely_topics']),
      (
        'Theory Questions',
        Icons.edit_note_rounded,
        prediction!['likely_theory_questions']
      ),
      ('Likely MCQs', Icons.checklist_rounded, prediction!['likely_mcqs']),
      (
        'High Priority Concepts',
        Icons.priority_high_rounded,
        prediction!['high_priority_concepts']
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Exam Prediction',
          action: IconButton(
              tooltip: 'Refresh prediction',
              onPressed: onGenerate,
              icon: const Icon(Icons.refresh_rounded)),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 760 ? 2 : 1;
            return ResponsiveGrid(
              columns: columns,
              spacing: 12,
              children: [
                for (final group in groups)
                  PredictionCard(
                      title: group.$1,
                      icon: group.$2,
                      items: (group.$3 as List<dynamic>? ?? [])
                          .map((e) => e.toString())
                          .toList()),
              ],
            );
          },
        ),
      ],
    );
  }
}

class PredictionCard extends StatelessWidget {
  const PredictionCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.items});

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfacePanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium))
          ]),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text('Not enough material yet.', style: theme.textTheme.bodyMedium)
          else
            for (final item in items.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class NoteProgressView extends StatelessWidget {
  const NoteProgressView({super.key, required this.note});

  final Map<String, dynamic> note;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Note Progress',
            action: FeaturePill(
                icon: Icons.offline_pin_rounded,
                label: 'Saved for offline review'),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 680 ? 3 : 1;
              return ResponsiveGrid(
                columns: columns,
                spacing: 12,
                children: const [
                  StatTile(
                      icon: Icons.summarize_rounded,
                      label: 'Workspace',
                      value: '6 tabs',
                      color: AppTheme.teal),
                  StatTile(
                      icon: Icons.repeat_rounded,
                      label: 'Revision',
                      value: 'Spaced',
                      color: AppTheme.amber),
                  StatTile(
                      icon: Icons.emoji_events_rounded,
                      label: 'Rewards',
                      value: 'Ready',
                      color: AppTheme.coral),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            'Use summary, chat, questions, cards, prediction, and quiz reports together for this material.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class PromptChip extends StatelessWidget {
  const PromptChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final Map<String, dynamic> message;

  @override
  Widget build(BuildContext context) {
    final role = message['role']?.toString() ?? 'assistant';
    final mine = role == 'user';
    final theme = Theme.of(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 620),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: mine
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SelectableText(
          message['message']?.toString() ?? '',
          style: theme.textTheme.bodyLarge?.copyWith(
              color: mine
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.api,
    required this.userId,
    required this.noteId,
    required this.questions,
    required this.mode,
    required this.difficulty,
  });

  final ApiClient api;
  final int userId;
  final int noteId;
  final List<Map<String, dynamic>> questions;
  final String mode;
  final String difficulty;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int index = 0;
  int score = 0;
  bool answered = false;
  bool submitting = false;
  final Map<int, String> answers = {};
  final startedAt = DateTime.now();
  final List<Map<String, dynamic>> wrongQuestions = [];
  final Set<int> flagged = {};
  late final Timer timer;
  int elapsedSeconds = 0;

  Map<String, dynamic> get item => widget.questions[index];
  List<dynamic> get options => item['options'] as List<dynamic>;
  String get correctAnswer => item['correct_answer']?.toString() ?? 'A';
  bool get showImmediateFeedback => widget.mode != 'mock';

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void choose(int optionIndex) {
    if (answered) return;
    final selected = String.fromCharCode(65 + optionIndex);
    HapticFeedback.selectionClick();
    answers[item['id'] as int? ?? index] = selected;
    if (selected == correctAnswer) {
      score++;
    } else {
      wrongQuestions.add(item);
    }
    setState(() => answered = true);
  }

  Future<void> next() async {
    if (index < widget.questions.length - 1) {
      setState(() {
        index++;
        answered = false;
      });
      return;
    }
    setState(() => submitting = true);
    try {
      await widget.api.submitQuiz(
        widget.userId,
        widget.noteId,
        answers,
        widget.mode,
        widget.difficulty,
        elapsedSeconds,
      );
    } catch (_) {
      // The result screen still matters even if score persistence fails.
    } finally {
      if (mounted) setState(() => submitting = false);
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuizResultDialog(
        score: score,
        total: widget.questions.length,
        wrongQuestions: wrongQuestions,
        onRetryWrong: wrongQuestions.isEmpty
            ? null
            : () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(
                      api: widget.api,
                      userId: widget.userId,
                      noteId: widget.noteId,
                      questions: wrongQuestions,
                      mode: 'retry',
                      difficulty: widget.difficulty,
                    ),
                  ),
                );
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (index + (answered ? 1 : 0)) / widget.questions.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'mock' ? 'Mock Exam' : 'Quiz Mode'),
        actions: [
          IconButton(
            tooltip:
                flagged.contains(index) ? 'Unflag question' : 'Flag question',
            onPressed: () => setState(() => flagged.contains(index)
                ? flagged.remove(index)
                : flagged.add(index)),
            icon: Icon(flagged.contains(index)
                ? Icons.flag_rounded
                : Icons.outlined_flag_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                              value: progress.clamp(0, 1), minHeight: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${index + 1}/${widget.questions.length}',
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FeaturePill(
                          icon: Icons.timer_rounded,
                          label: formatDuration(elapsedSeconds)),
                      FeaturePill(
                          icon: Icons.tune_rounded, label: widget.difficulty),
                      FeaturePill(
                          icon: Icons.extension_rounded, label: widget.mode),
                      if (flagged.isNotEmpty)
                        FeaturePill(
                            icon: Icons.flag_rounded,
                            label: '${flagged.length} flagged'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.questions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, number) {
                        final key =
                            widget.questions[number]['id'] as int? ?? number;
                        final done = answers.containsKey(key);
                        return Tooltip(
                          message: flagged.contains(number)
                              ? 'Flagged question ${number + 1}'
                              : 'Question ${number + 1}',
                          child: ChoiceChip(
                            label: Text('${number + 1}'),
                            selected: index == number,
                            avatar: flagged.contains(number)
                                ? const Icon(Icons.flag_rounded, size: 16)
                                : done
                                    ? const Icon(Icons.check_rounded, size: 16)
                                    : null,
                            onSelected: (_) => setState(() {
                              index = number;
                              answered = done;
                            }),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        SurfacePanel(
                          padding: const EdgeInsets.all(20),
                          child: Text(item['question']?.toString() ?? '',
                              style: theme.textTheme.titleLarge),
                        ),
                        const SizedBox(height: 14),
                        for (var i = 0; i < options.length; i++)
                          QuizOptionButton(
                            letter: String.fromCharCode(65 + i),
                            text: options[i].toString(),
                            answered: answered && showImmediateFeedback,
                            correctAnswer: correctAnswer,
                            selectedAnswer:
                                answers[item['id'] as int? ?? index],
                            onTap: () => choose(i),
                          ),
                        if (answered && showImmediateFeedback) ...[
                          const SizedBox(height: 8),
                          SurfacePanel(
                            padding: const EdgeInsets.all(14),
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.7),
                            child: Text(item['explanation']?.toString() ??
                                'Review this answer in your note.'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: answered && !submitting ? next : null,
                    icon: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(index == widget.questions.length - 1
                            ? Icons.flag_rounded
                            : Icons.arrow_forward_rounded),
                    label: Text(index == widget.questions.length - 1
                        ? 'Finish quiz'
                        : 'Next question'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuizOptionButton extends StatelessWidget {
  const QuizOptionButton({
    super.key,
    required this.letter,
    required this.text,
    required this.answered,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool answered;
  final String correctAnswer;
  final String? selectedAnswer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = letter == correctAnswer;
    final isSelected = letter == selectedAnswer;
    final color = answered && isCorrect
        ? const Color(0xff2e9d62)
        : answered && isSelected
            ? AppTheme.coral
            : theme.colorScheme.surfaceContainerHighest;
    final foreground = answered && (isCorrect || isSelected)
        ? Colors.white
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: answered ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: foreground.withValues(alpha: 0.16),
                child: Text(letter,
                    style: TextStyle(
                        color: foreground, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(text,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: foreground))),
              if (answered && isCorrect)
                Icon(Icons.check_circle_rounded, color: foreground),
              if (answered && isSelected && !isCorrect)
                Icon(Icons.cancel_rounded, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizResultDialog extends StatelessWidget {
  const QuizResultDialog({
    super.key,
    required this.score,
    required this.total,
    required this.wrongQuestions,
    this.onRetryWrong,
  });

  final int score;
  final int total;
  final List<Map<String, dynamic>> wrongQuestions;
  final VoidCallback? onRetryWrong;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : ((score / total) * 100).round();
    return AlertDialog(
      title: const Text('Quiz complete'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressBadge(percent: percent, label: '$percent%'),
          const SizedBox(height: 16),
          Text('Score: $score/$total',
              style: Theme.of(context).textTheme.titleLarge),
          if (wrongQuestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
                '${wrongQuestions.length} question${wrongQuestions.length == 1 ? '' : 's'} to review'),
          ],
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(
                text: 'I scored $score/$total ($percent%) on ExamAI.'));
            Navigator.of(context).pop();
            showMessage(context, 'Score card copied.');
          },
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Share card'),
        ),
        if (onRetryWrong != null)
          TextButton(
            onPressed: onRetryWrong,
            child: const Text('Retry missed'),
          ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Dashboard'),
        ),
      ],
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ExamAI logo',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          brandLogoAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.school_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: size * 0.58),
          ),
        ),
      ),
    );
  }
}

class StudyIllustration extends StatelessWidget {
  const StudyIllustration(
      {super.key, required this.icon, required this.color, this.size = 126});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.24)),
              ),
            ),
          ),
          Positioned(
            left: size * 0.16,
            bottom: size * 0.16,
            child: Container(
              width: size * 0.42,
              height: size * 0.28,
              decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          Positioned(
            right: size * 0.14,
            top: size * 0.16,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.72),
                  shape: BoxShape.circle),
            ),
          ),
          Container(
            width: size * 0.54,
            height: size * 0.54,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: size * 0.32, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class SurfacePanel extends StatelessWidget {
  const SurfacePanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.color});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.55)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, this.tooltip});

  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton.filledTonal(
      tooltip: tooltip ?? (isDark ? 'Light theme' : 'Dark theme'),
      onPressed: () =>
          appThemeMode.value = isDark ? ThemeMode.light : ThemeMode.dark,
      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
    );
  }
}

class FeaturePill extends StatelessWidget {
  const FeaturePill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 7),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid(
      {super.key,
      required this.columns,
      required this.spacing,
      required this.children});

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfacePanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.headlineSmall),
                Text(label,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, required this.onTap});

  final Map<String, dynamic> note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SurfacePanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.menu_book_rounded,
                      color: theme.colorScheme.primary),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 14),
            Text(note['title']?.toString() ?? 'Untitled note',
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(
              note['file_name']?.toString().isNotEmpty == true
                  ? note['file_name'].toString()
                  : 'Text note',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(note['created_at']?.toString() ?? '',
                style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class QuizHistoryTile extends StatelessWidget {
  const QuizHistoryTile({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final score = item['score'] as num? ?? 0;
    final total = item['total_questions'] as num? ?? 1;
    final percent = total == 0 ? 0 : ((score / total) * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfacePanel(
        child: Row(
          children: [
            ProgressBadge(percent: percent, label: '$percent%', compact: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title']?.toString() ?? 'Quiz',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('$score/$total correct',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressBadge extends StatelessWidget {
  const ProgressBadge(
      {super.key,
      required this.percent,
      required this.label,
      this.compact = false});

  final int percent;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 54.0 : 118.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percent.clamp(0, 100) / 100,
            strokeWidth: compact ? 6 : 10,
            backgroundColor:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
          ),
          Center(
            child: Text(label,
                style: compact
                    ? Theme.of(context).textTheme.labelLarge
                    : Theme.of(context).textTheme.headlineSmall),
          ),
        ],
      ),
    );
  }
}

class FileDropPanel extends StatelessWidget {
  const FileDropPanel(
      {super.key,
      required this.selectedFile,
      required this.onPick,
      this.onClear});

  final PlatformFile? selectedFile;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(8),
      child: SurfacePanel(
        padding: const EdgeInsets.all(18),
        color: selectedFile == null
            ? null
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        child: Row(
          children: [
            Icon(
                selectedFile == null
                    ? Icons.attach_file_rounded
                    : Icons.description_rounded,
                size: 34,
                color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectedFile?.name ?? 'Choose PDF or text file',
                      style: theme.textTheme.titleMedium),
                  Text(
                    selectedFile == null
                        ? 'PDF and TXT files are supported'
                        : readableBytes(selectedFile!.size),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                tooltip: 'Remove file',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              )
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (action != null) action!,
      ],
    );
  }
}

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: 14),
          Expanded(
              child:
                  Text(label, style: Theme.of(context).textTheme.titleMedium)),
        ],
      ),
    );
  }
}

class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({super.key, required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return EmptyActionPanel(
      icon: Icons.auto_stories_rounded,
      title: 'Your library is empty',
      message: 'Add your first note and build a study session around it.',
      buttonLabel: 'Add note',
      onPressed: onUpload,
    );
  }
}

class EmptyActionPanel extends StatelessWidget {
  const EmptyActionPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfacePanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudyIllustration(
              icon: icon, color: theme.colorScheme.primary, size: 112),
          const SizedBox(height: 14),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(message,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (onPressed != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add_rounded),
                label: Text(buttonLabel)),
          ],
        ],
      ),
    );
  }
}

class ActionChipButton extends StatelessWidget {
  const ActionChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon),
      label: Text(label),
    );
  }
}

class McqPreview extends StatelessWidget {
  const McqPreview({super.key, required this.index, required this.item});

  final int index;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = (item['options'] as List<dynamic>? ?? []);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfacePanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index + 1}. ${item['question']}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            for (var i = 0; i < options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${String.fromCharCode(65 + i)}. ${options[i]}'),
              ),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> normalizeQuestion(Map<String, dynamic> item) {
  final options = item['options'] as List<dynamic>? ??
      [
        item['option_a'],
        item['option_b'],
        item['option_c'],
        item['option_d'],
      ];
  return {
    'id': item['id'],
    'question': item['question'],
    'options': options.where((option) => option != null).toList(),
    'correct_answer': item['correct_answer'] ?? 'A',
    'explanation': item['explanation'] ?? '',
  };
}

String readableBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}

String formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
    ),
  );
}
