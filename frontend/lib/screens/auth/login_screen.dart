import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/calm_background.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.initialApi, required this.onSuccess, required this.onThemeToggle, required this.themeMode});
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
  void initState() { super.initState(); apiText.text = widget.initialApi.baseUrl; }
  @override
  void dispose() { name.dispose(); email.dispose(); password.dispose(); apiText.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(body: CalmBackground(child: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: wide ? Row(children: [const Expanded(flex: 6, child: LoginStoryPanel()), const SizedBox(width: 28), Expanded(flex: 4, child: _formCard())]) : Column(children: [const LoginStoryPanel(compact: true), const SizedBox(height: 20), _formCard()])))))));
  }

  Widget _formCard() => SoftCard(padding: const EdgeInsets.all(26), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
    Row(children: [Expanded(child: Text(signup ? 'Create your calm study space' : 'Welcome back', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900))), IconButton.filledTonal(tooltip: 'Light / dark mode', onPressed: widget.onThemeToggle, icon: Icon(widget.themeMode == ThemeMode.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded)), const SizedBox(width: 8), IconButton.filledTonal(tooltip: 'Backend settings', onPressed: () => setState(() => showApi = !showApi), icon: const Icon(Icons.tune_rounded))]),
    const SizedBox(height: 8), const SoftText('No pressure. One step at a time.'), const SizedBox(height: 18),
    if (error != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(.10), borderRadius: BorderRadius.circular(16)), child: Text(error!)),
    if (showApi) ...[TextField(controller: apiText, decoration: const InputDecoration(labelText: 'Backend API URL', prefixIcon: Icon(Icons.cloud_queue_rounded))), const SizedBox(height: 12), OutlinedButton.icon(onPressed: busy ? null : _testApi, icon: const Icon(Icons.wifi_tethering_rounded), label: const Text('Test backend')), const SizedBox(height: 12)],
    if (signup) ...[TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.badge_rounded))), const SizedBox(height: 12)],
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))), const SizedBox(height: 12),
    TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded))), const SizedBox(height: 18),
    PrimaryCalmButton(label: busy ? 'Working...' : signup ? 'Create account' : 'Login', icon: signup ? Icons.person_add_rounded : Icons.login_rounded, onTap: busy ? null : _submit),
    const SizedBox(height: 12), TextButton(onPressed: busy ? null : () => setState(() => signup = !signup), child: Text(signup ? 'I already have an account' : 'Create a new account')),
    Center(child: Text('Demo: student@example.com / password123', style: TextStyle(color: muted(context), fontWeight: FontWeight.w700, fontSize: 12))),
  ]));

  String _apiBase() { var value = apiText.text.trim().isEmpty ? widget.initialApi.baseUrl : apiText.text.trim(); if (!value.startsWith('http')) value = 'https://$value'; if (value.endsWith('/')) value = value.substring(0, value.length - 1); return value; }
  Future<void> _testApi() async { setState(() { busy = true; error = null; }); final ok = await ApiClient(_apiBase()).ping(); if (!mounted) return; setState(() { busy = false; error = ok ? null : 'Backend did not respond. Check your Render URL.'; }); if (ok) toast(context, 'Backend connected.'); }
  Future<void> _submit() async { setState(() { busy = true; error = null; }); final api = ApiClient(_apiBase()); try { final nextUser = signup ? await api.register(name.text, email.text, password.text) : await api.login(email.text, password.text); await widget.onSuccess(api, nextUser); } catch (e) { setState(() => error = e.toString().replaceFirst('Exception: ', '')); } finally { if (mounted) setState(() => busy = false); } }
}

class LoginStoryPanel extends StatelessWidget {
  const LoginStoryPanel({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => SoftCard(padding: EdgeInsets.all(compact ? 22 : 34), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const StudentMascot(size: 116, mood: MascotMood.wave), const SizedBox(width: 18), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ExamAI', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 6), const SoftText('A friendly study coach for every student.')]))]),
    if (!compact) ...[const SizedBox(height: 30), const Text('Study with less stress and more direction.', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, height: 1.05)), const SizedBox(height: 16), const SoftText('ExamAI guides your day, explains difficult topics, tracks weak areas, and keeps advanced tools tucked away until you need them.', size: 17), const SizedBox(height: 24), const Wrap(spacing: 10, runSpacing: 10, children: [CalmPill(icon: Icons.psychology_rounded, label: 'AI study brain'), CalmPill(icon: Icons.checklist_rounded, label: 'Daily flow'), CalmPill(icon: Icons.style_rounded, label: 'Flashcards'), CalmPill(icon: Icons.auto_awesome_rounded, label: 'Gentle design')])]
  ]));
}
