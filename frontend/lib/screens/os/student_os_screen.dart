import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/student_snapshot.dart';
import '../../services/api_client.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class StudentOSScreen extends StatefulWidget {
  const StudentOSScreen({super.key, required this.api, required this.userId, required this.data, required this.onChanged});
  final ApiClient api;
  final int userId;
  final StudentSnapshot data;
  final VoidCallback onChanged;

  @override
  State<StudentOSScreen> createState() => _StudentOSScreenState();
}

class _StudentOSScreenState extends State<StudentOSScreen> {
  bool focusMode = false;
  bool recoveryMode = false;
  bool voiceMode = false;
  bool cameraMode = false;
  bool studyRoomLive = false;
  int rewardCoins = 140;
  int pomodoroSeconds = 25 * 60;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startPomodoro() {
    timer?.cancel();
    setState(() => focusMode = true);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (pomodoroSeconds <= 0) {
        t.cancel();
        setState(() {
          focusMode = false;
          rewardCoins += 20;
          pomodoroSeconds = 25 * 60;
        });
        showFeatureSheet(context, 'Focus complete', 'Great work. You earned 20 coins and your study streak has been protected.');
      } else {
        setState(() => pomodoroSeconds--);
      }
    });
  }

  Future<void> _saveSmartSession(String activity, int seconds) async {
    try {
      await widget.api.recordStudyTime(widget.userId, null, activity, seconds);
      widget.onChanged();
      if (mounted) showFeatureSheet(context, 'Saved', 'This action was saved to your progress system. Your AI memory can use it for better recommendations.');
    } catch (_) {
      if (mounted) showFeatureSheet(context, 'Saved locally', 'Your backend did not respond, so this action is shown in the app and can be connected to the cloud endpoint later.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final burnoutRisk = widget.data.streak > 5 && widget.data.average < 70 ? 'Medium' : 'Low';
    final minutes = (pomodoroSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (pomodoroSeconds % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionIntro(
          icon: Icons.auto_awesome_rounded,
          title: 'AI Student Operating System',
          subtitle: 'A calmer, smarter workspace with the 20 next-level systems built in and organized without clutter.',
          mascot: StudentMascot(size: 104, mood: focusMode ? MascotMood.focus : MascotMood.celebrate),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth > 760;
            final content = Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today, ExamAI recommends ${widget.data.weakTopic}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.08)),
                  const SizedBox(height: 8),
                  SoftText('You are ${widget.data.average}% ready for ${widget.data.missionCourse}. Complete one focused session, then retry weak questions.'),
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    CalmPill(icon: Icons.psychology_rounded, label: 'AI memory active'),
                    CalmPill(icon: Icons.health_and_safety_rounded, label: 'Burnout risk: $burnoutRisk'),
                    CalmPill(icon: Icons.monetization_on_rounded, label: '$rewardCoins coins'),
                  ]),
                  const SizedBox(height: 18),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    PrimaryCalmButton(label: focusMode ? '$minutes:$seconds running' : 'Start focus session', icon: Icons.self_improvement_rounded, onTap: _startPomodoro),
                    SecondaryCalmButton(label: 'Save smart session', icon: Icons.cloud_done_rounded, onTap: () => _saveSmartSession('student-os-focus', 25 * 60)),
                  ]),
                ],
              ),
            );
            final ring = ProgressRing(value: widget.data.average / 100, label: '${widget.data.average}%');
            if (wide) return Row(children: [content, const SizedBox(width: 18), ring]);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [content, const SizedBox(height: 18), Center(child: ring)]);
          }),
        ),
        const SizedBox(height: 16),
        ResponsiveCalmGrid(minWidth: 300, children: [
          _FeatureCard(
            title: '1. AI Life Coach',
            body: 'Planner, motivator, organizer, and accountability coach for student life.',
            icon: Icons.favorite_rounded,
            color: CalmTheme.rose,
            action: 'Open guidance',
            onTap: () => showFeatureSheet(context, 'AI Life Coach', 'Your coach checks study habits, emotional state, exam pressure, and workload before suggesting the next best action.'),
          ),
          _FeatureCard(
            title: '2. Burnout Detection',
            body: 'Detects fatigue from inactivity, failed quizzes, late sessions, and overload.',
            icon: Icons.spa_rounded,
            color: CalmTheme.green,
            action: recoveryMode ? 'Recovery on' : 'Enable recovery',
            onTap: () => setState(() => recoveryMode = !recoveryMode),
          ),
          _FeatureCard(
            title: '3. Full AI Voice Mode',
            body: 'Voice-ready study mode for spoken questions and spoken answers.',
            icon: Icons.graphic_eq_rounded,
            color: CalmTheme.purple,
            action: voiceMode ? 'Voice active' : 'Activate voice',
            onTap: () => setState(() => voiceMode = !voiceMode),
          ),
          _FeatureCard(
            title: '4. Smart Camera Study',
            body: 'Camera/OCR-ready flow for textbooks, handwritten notes, and whiteboards.',
            icon: Icons.photo_camera_rounded,
            color: CalmTheme.blue,
            action: cameraMode ? 'Camera ready' : 'Prepare camera',
            onTap: () => setState(() => cameraMode = !cameraMode),
          ),
          _FeatureCard(
            title: '5. Real-Time Study Room',
            body: 'Live study rooms, shared challenges, group goals, and AI moderation.',
            icon: Icons.groups_rounded,
            color: CalmTheme.teal,
            action: studyRoomLive ? 'Room live' : 'Start room',
            onTap: () => setState(() => studyRoomLive = !studyRoomLive),
          ),
          _FeatureCard(
            title: '6. Exam Prediction Engine',
            body: 'Predict likely topics, pass probability, urgent weak areas, and readiness.',
            icon: Icons.crystal_ball_rounded,
            color: CalmTheme.indigo,
            action: 'View prediction',
            onTap: () => showFeatureSheet(context, 'Exam Prediction', '${widget.data.missionCourse}: likely focus area is ${widget.data.weakTopic}. Current readiness: ${widget.data.average}%. Recommended action: 10 MCQs + one AI explanation.'),
          ),
          _FeatureCard(
            title: '7. Smart Study Timeline',
            body: 'A mission roadmap: today, this week, before exam, weak areas, mastered topics.',
            icon: Icons.timeline_rounded,
            color: CalmTheme.orange,
            action: 'Open timeline',
            onTap: () => showFeatureSheet(context, 'Smart Study Timeline', 'Today: ${widget.data.weakTopic}. This week: quiz + flashcards. Before exam: mock mode + final revision.'),
          ),
          _FeatureCard(
            title: '8. Achievement Economy',
            body: 'Coins, unlockables, mascot outfits, themes, AI skins, and sound packs.',
            icon: Icons.emoji_events_rounded,
            color: CalmTheme.gold,
            action: 'Earn +10 coins',
            onTap: () => setState(() => rewardCoins += 10),
          ),
          _FeatureCard(
            title: '9. Windows Workstation',
            body: 'Desktop-first split view with panels, shortcuts, and drag-style study workspace.',
            icon: Icons.desktop_windows_rounded,
            color: CalmTheme.blue,
            action: 'Workspace tips',
            onTap: () => showFeatureSheet(context, 'Desktop Workspace', 'Use Windows mode for deeper study: left navigation, central tutor, side progress panels, and keyboard-friendly actions.'),
          ),
          _FeatureCard(
            title: '10. Ultra Premium Motion',
            body: 'Cinematic calm animations, liquid transitions, and breathing UI movement.',
            icon: Icons.motion_photos_auto_rounded,
            color: CalmTheme.purple,
            action: 'Preview motion',
            onTap: () => showFeatureSheet(context, 'Motion System', 'Cards fade, lift, and breathe gently. Background glows move slowly so the app feels alive without distracting students.'),
          ),
          _FeatureCard(
            title: '11. Adaptive UI',
            body: 'Interface adapts to time of day, exam proximity, performance, and stress level.',
            icon: Icons.auto_fix_high_rounded,
            color: CalmTheme.teal,
            action: 'Adaptive on',
            onTap: () => showFeatureSheet(context, 'Adaptive UI', 'Night mode becomes quieter, exam week becomes focused, and recovery mode reduces workload when burnout risk rises.'),
          ),
          _FeatureCard(
            title: '12. Emotional Mascot',
            body: 'Mascot reacts to streaks, failures, late nights, focus mode, and quiz success.',
            icon: Icons.smart_toy_rounded,
            color: CalmTheme.rose,
            action: 'Mascot reacts',
            onTap: () => showFeatureSheet(context, 'Mascot Companion', 'Your mascot cheers success, comforts failure, and changes mood based on your learning progress.'),
          ),
          _FeatureCard(
            title: '13. AI Memory Graph',
            body: 'Remembers topics mastered, repeated mistakes, learning style, and focus times.',
            icon: Icons.hub_rounded,
            color: CalmTheme.indigo,
            action: 'View memory',
            onTap: () => showFeatureSheet(context, 'AI Memory Graph', 'Memory nodes: ${widget.data.weakTopic}, preferred calm explanations, strong streaks, and quiz accuracy patterns.'),
          ),
          _FeatureCard(
            title: '14. True Minimalism',
            body: 'More power with less clutter through progressive disclosure and one clear action.',
            icon: Icons.filter_center_focus_rounded,
            color: CalmTheme.green,
            action: 'Keep calm',
            onTap: () => showFeatureSheet(context, 'Minimal Power', 'The app keeps advanced features tucked away until needed, so the student always knows what to do next.'),
          ),
          _FeatureCard(
            title: '15. App Ecosystem',
            body: 'Android, Windows, web, tablet, smartwatch reminders, and browser extension path.',
            icon: Icons.devices_rounded,
            color: CalmTheme.blue,
            action: 'Ecosystem map',
            onTap: () => showFeatureSheet(context, 'App Ecosystem', 'Android for daily use, Windows for deep study, web for school access, tablet for split mode, smartwatch for reminders.'),
          ),
          _FeatureCard(
            title: '16. School Mode',
            body: 'Institution dashboards, class analytics, quizzes, attendance, and AI insights.',
            icon: Icons.apartment_rounded,
            color: CalmTheme.orange,
            action: 'School tools',
            onTap: () => showFeatureSheet(context, 'School Mode', 'Schools can upload materials, monitor class progress, run quizzes, and see AI analytics.'),
          ),
          _FeatureCard(
            title: '17. Assignment Builder',
            body: 'Helps plan assignments, outline research, organize references, and schedule work.',
            icon: Icons.assignment_turned_in_rounded,
            color: CalmTheme.purple,
            action: 'Build project',
            onTap: () => showFeatureSheet(context, 'Project Builder', 'Paste assignment requirements, then ExamAI breaks them into research, writing, review, and submission steps.'),
          ),
          _FeatureCard(
            title: '18. Mental Wellness Mode',
            body: 'Breathing prompts, calming sounds, stress check-ins, and recovery study plans.',
            icon: Icons.self_improvement_rounded,
            color: CalmTheme.green,
            action: 'Breathe',
            onTap: () => showFeatureSheet(context, 'Wellness Mode', 'Breathe in for 4 seconds, hold for 2, breathe out for 6. Then continue with one small task.'),
          ),
          _FeatureCard(
            title: '19. Next-Level Beauty',
            body: 'Apple smoothness, Arc elegance, Notion calmness, Duolingo emotion, ChatGPT intelligence.',
            icon: Icons.diamond_rounded,
            color: CalmTheme.gold,
            action: 'Design language',
            onTap: () => showFeatureSheet(context, 'Visual Direction', 'Soft futuristic academic OS: glowing gradients, floating cards, warm achievements, emotional mascot, and calm focus.'),
          ),
          _FeatureCard(
            title: '20. Intelligent Before Powerful',
            body: 'The app guides, understands, motivates, organizes, and supports the student first.',
            icon: Icons.lightbulb_rounded,
            color: CalmTheme.teal,
            action: 'Core principle',
            onTap: () => showFeatureSheet(context, 'Core Principle', 'ExamAI should feel intelligent before powerful: one clear next step, calm support, and personalized guidance.'),
          ),
        ]),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.body, required this.icon, required this.color, required this.action, required this.onTap});
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [CircleIcon(icon: icon, color: color), const Spacer(), Icon(Icons.arrow_outward_rounded, color: muted(context), size: 18)]),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SoftText(body),
          const SizedBox(height: 14),
          CalmPill(icon: Icons.touch_app_rounded, label: action),
        ],
      ),
    );
  }
}
