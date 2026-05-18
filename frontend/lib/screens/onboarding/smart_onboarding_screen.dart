import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme/calm_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/calm_background.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class SmartOnboardingScreen extends StatefulWidget {
  const SmartOnboardingScreen({
    super.key,
    required this.api,
    required this.user,
    required this.onComplete,
    required this.onLogout,
  });

  final ApiClient api;
  final Map<String, dynamic> user;
  final Future<void> Function(Map<String, dynamic> user) onComplete;
  final VoidCallback onLogout;

  @override
  State<SmartOnboardingScreen> createState() => _SmartOnboardingScreenState();
}

class _SmartOnboardingScreenState extends State<SmartOnboardingScreen> {
  final course = TextEditingController(text: 'CSC301');
  final examDate = TextEditingController();
  final struggle = TextEditingController(text: 'Recursion');
  double targetScore = 80;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(days: 23));
    examDate.text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    course.dispose();
    examDate.dispose();
    struggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user['full_name']?.toString().split(' ').first ?? 'Scholar';
    return Scaffold(
      body: CalmBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: SoftCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const StudentMascot(size: 104, mood: MascotMood.wave),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Let ExamAI adapt to you, $firstName', style: Theme.of(context).textTheme.headlineSmall),
                                const SizedBox(height: 8),
                                const SoftText('Three answers are enough to build your first exam mission.'),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Logout',
                            onPressed: saving ? null : widget.onLogout,
                            icon: const Icon(Icons.logout_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      if (error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(.10), borderRadius: BorderRadius.circular(12)),
                          child: Text(error!),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: course,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'What are you studying?', prefixIcon: Icon(Icons.school_rounded), hintText: 'CSC301, BIO204, GST101'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: examDate,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(labelText: 'When is your next exam?', prefixIcon: Icon(Icons.event_rounded), hintText: 'YYYY-MM-DD'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: struggle,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'What is your biggest struggle?', prefixIcon: Icon(Icons.psychology_rounded), hintText: 'Recursion, genetics, essay structure'),
                      ),
                      const SizedBox(height: 18),
                      Text('Target score: ${targetScore.round()}%', style: const TextStyle(fontWeight: FontWeight.w900)),
                      Slider(
                        value: targetScore,
                        min: 50,
                        max: 100,
                        divisions: 10,
                        activeColor: CalmTheme.teal,
                        label: '${targetScore.round()}%',
                        onChanged: saving ? null : (value) => setState(() => targetScore = value),
                      ),
                      const SizedBox(height: 12),
                      const Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          CalmPill(icon: Icons.event_available_rounded, label: 'Exam countdown'),
                          CalmPill(icon: Icons.auto_graph_rounded, label: 'Readiness score'),
                          CalmPill(icon: Icons.style_rounded, label: 'Spaced review'),
                        ],
                      ),
                      const SizedBox(height: 22),
                      PrimaryCalmButton(
                        label: saving ? 'Building your study plan...' : 'Build my study plan',
                        icon: Icons.auto_awesome_rounded,
                        onTap: saving ? null : _save,
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

  Future<void> _save() async {
    if (course.text.trim().isEmpty || examDate.text.trim().isEmpty || struggle.text.trim().isEmpty) {
      setState(() => error = 'Please answer all three questions so ExamAI can personalize your dashboard.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final userId = (widget.user['id'] as num?)?.toInt() ?? 1;
      final nextUser = await widget.api.completeOnboarding(
        userId,
        course: course.text,
        examDate: examDate.text,
        struggle: struggle.text,
        targetScore: targetScore.round(),
      );
      await widget.onComplete(nextUser);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
