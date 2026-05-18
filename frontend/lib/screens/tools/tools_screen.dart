import 'package:flutter/material.dart';
import '../../models/student_snapshot.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({
    super.key,
    required this.data,
    required this.goRooms,
    required this.goOffline,
    required this.goSchool,
    required this.goLecturer,
    required this.goVoice,
    required this.goDiagnostics,
  });

  final StudentSnapshot data;
  final VoidCallback goRooms;
  final VoidCallback goOffline;
  final VoidCallback goSchool;
  final VoidCallback goLecturer;
  final VoidCallback goVoice;
  final VoidCallback goDiagnostics;

  @override
  Widget build(BuildContext context) => AnimatedSection(children: [
        const SectionIntro(icon: Icons.dashboard_customize_rounded, title: 'Academic OS Hub', subtitle: 'Everything that turns ExamAI from a study helper into a full student operating system.', mascot: StudentMascot(size: 100, mood: MascotMood.celebrate)),
        const SizedBox(height: 16),
        ResponsiveCalmGrid(minWidth: 230, children: [
          CalmMetric(title: data.missionCourse, value: '${data.daysLeft} days', subtitle: '${data.average}% ready', icon: Icons.event_available_rounded, color: CalmTheme.teal),
          CalmMetric(title: 'Next action', value: data.examRisk.toUpperCase(), subtitle: data.weakTopic, icon: Icons.assistant_direction_rounded, color: CalmTheme.orange),
          CalmMetric(title: 'Tutor tone', value: data.emotionalTone.replaceAll('_', ' '), subtitle: 'adaptive support', icon: Icons.favorite_rounded, color: CalmTheme.rose),
        ]),
        const SizedBox(height: 16),
        ResponsiveCalmGrid(minWidth: 260, children: [
          _PillarCard(title: 'Adaptive intelligence', body: 'Difficulty, tutor style, mission, readiness, and emotional tone update from every action.', icon: Icons.auto_graph_rounded, color: CalmTheme.teal, onTap: goDiagnostics),
          _PillarCard(title: 'Spaced repetition', body: 'Questions and flashcards return when memory is about to fade.', icon: Icons.style_rounded, color: CalmTheme.purple, onTap: () => showFeatureSheet(context, 'Spaced repetition', 'The backend mastery engine already stores ease, interval, and next review dates. The next step is exposing due review queues across flashcards and quizzes.')),
          _PillarCard(title: 'Study with friends', body: 'Small rooms, shared timers, group quizzes, and invite codes for class groups.', icon: Icons.groups_rounded, color: CalmTheme.green, onTap: goRooms),
          _PillarCard(title: 'Offline-first', body: 'Cached notes, plans, quiz actions, and sync queue for unreliable networks.', icon: Icons.offline_bolt_rounded, color: CalmTheme.orange, onTap: goOffline),
          _PillarCard(title: 'Curriculum aware', body: 'WAEC, JAMB, Nigerian universities, GCSE, SAT, AP, IB, and lecturer course packs.', icon: Icons.account_balance_rounded, color: CalmTheme.indigo, onTap: goSchool),
          _PillarCard(title: 'Lecturer tools', body: 'Course codes, generated materials, assignments, and anonymized class insight.', icon: Icons.co_present_rounded, color: CalmTheme.blue, onTap: goLecturer),
          _PillarCard(title: 'Voice and languages', body: 'Ask aloud in English, Pidgin, Yoruba, Igbo, Hausa, French, or Swahili.', icon: Icons.record_voice_over_rounded, color: CalmTheme.rose, onTap: goVoice),
          _PillarCard(title: 'Widget and smart reminders', body: 'One useful daily prompt, streak/task snapshot, and one-tap study entry for the phone home screen.', icon: Icons.widgets_rounded, color: CalmTheme.gold, onTap: () => showFeatureSheet(context, 'Widget and reminders', 'Native Android widget and push delivery require platform setup. The UX target is: one task count, streak, exam countdown, and one useful reminder at the student usual study time.')),
          _PillarCard(title: 'Trust and privacy', body: 'Consent-first reports, transparent AI, export/delete controls, and school-safe analytics.', icon: Icons.privacy_tip_rounded, color: CalmTheme.graphite, onTap: () => showFeatureSheet(context, 'Trust layer', 'Production readiness needs encrypted secrets, consent logs, data export/delete, school audit logs, and clear AI transparency controls.')),
        ]),
      ]);
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({required this.title, required this.body, required this.icon, required this.color, required this.onTap});
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SoftCard(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleIcon(icon: icon, color: color),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SoftText(body),
        const SizedBox(height: 12),
        Icon(Icons.arrow_forward_rounded, color: color),
      ]));
}
