import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/calm_background.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
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
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    apiText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final horizontal = width < 430 ? 14.0 : 22.0;

    return Scaffold(
      body: CalmBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(flex: 6, child: LoginStoryPanel()),
                          const SizedBox(width: 28),
                          Expanded(flex: 4, child: _formCard(context)),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LoginStoryPanel(compact: true),
                          const SizedBox(height: 16),
                          _formCard(context),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 430;

    return SoftCard(
      padding: EdgeInsets.all(compact ? 18 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  signup ? 'Create your calm study space' : 'Welcome back',
                  style: TextStyle(
                    fontSize: compact ? 30 : 34,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
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
          if (error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.red.withOpacity(.10), borderRadius: BorderRadius.circular(18)),
              child: Text(error!, style: const TextStyle(height: 1.35)),
            ),
          if (showApi) ...[
            TextField(
              controller: apiText,
              decoration: const InputDecoration(labelText: 'Backend API URL', prefixIcon: Icon(Icons.cloud_queue_rounded)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : _testApi,
              icon: const Icon(Icons.wifi_tethering_rounded),
              label: const Text('Test backend'),
            ),
            const SizedBox(height: 12),
          ],
          if (signup) ...[
            TextField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.badge_rounded)),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: password,
            obscureText: true,
            onSubmitted: (_) => busy ? null : _submit(),
            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded)),
          ),
          const SizedBox(height: 20),
          PrimaryCalmButton(
            label: busy ? 'Working...' : signup ? 'Create account' : 'Login',
            icon: signup ? Icons.person_add_rounded : Icons.login_rounded,
            onTap: busy ? null : _submit,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: busy ? null : () => setState(() => signup = !signup),
            child: Text(signup ? 'I already have an account' : 'Create a new account'),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              'Your study data stays under your control.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted(context), fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _apiBase() {
    var value = apiText.text.trim().isEmpty ? widget.initialApi.baseUrl : apiText.text.trim();
    if (!value.startsWith('http')) value = 'https://$value';
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
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
      error = ok ? null : 'Backend did not respond. Check your Render URL or internet connection.';
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
      final nextUser = signup
          ? await api.register(name.text.trim().isEmpty ? 'Student' : name.text, email.text, password.text)
          : await api.login(email.text, password.text);
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
  Widget build(BuildContext context) => SoftCard(
        padding: EdgeInsets.all(compact ? 18 : 34),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 430 || compact;
            return mobile
                ? Row(
                    children: [
                      const StudentMascot(size: 100, mood: MascotMood.wave),
                      const SizedBox(width: 16),
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
                  )
                : Column(
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
                  );
          },
        ),
      );
}
