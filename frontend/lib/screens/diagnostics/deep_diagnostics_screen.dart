import 'package:flutter/material.dart';
import '../../models/student_snapshot.dart';
import '../../theme/calm_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class DeepDiagnosticsScreen extends StatelessWidget {
  const DeepDiagnosticsScreen({super.key, required this.data});
  final StudentSnapshot data;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionIntro(icon: Icons.psychology_alt_rounded, title: 'Weak Area Diagnosis', subtitle: 'ExamAI should identify not only what is weak, but why the understanding breaks.', mascot: StudentMascot(size: 100, mood: MascotMood.focus)),
        const SizedBox(height: 16),
        ResponsiveCalmGrid(minWidth: 230, children: [
          CalmMetric(title: 'Focus', value: data.weakTopic, subtitle: 'current weak area', icon: Icons.center_focus_strong_rounded, color: CalmTheme.teal),
          CalmMetric(title: 'Tone', value: data.emotionalTone.replaceAll('_', ' '), subtitle: 'support mode', icon: Icons.favorite_rounded, color: CalmTheme.rose),
          CalmMetric(title: 'Readiness', value: '${data.average}%', subtitle: '${data.daysLeft} days left', icon: Icons.insights_rounded, color: CalmTheme.green),
        ]),
        const SizedBox(height: 16),
        ResponsiveCalmGrid(minWidth: 260, children: const [
          _GapCard(title: 'Conceptual gap', body: 'The idea itself is unclear. Use analogies and small examples.', icon: Icons.lightbulb_rounded, color: CalmTheme.gold),
          _GapCard(title: 'Application gap', body: 'The idea is understood but hard to apply in new problems.', icon: Icons.code_rounded, color: CalmTheme.teal),
          _GapCard(title: 'Exam-format gap', body: 'The student knows the topic but misses how exams ask it.', icon: Icons.edit_document, color: CalmTheme.orange),
          _GapCard(title: 'Recall gap', body: 'The concept needs spaced repetition before it fades.', icon: Icons.style_rounded, color: CalmTheme.purple),
        ]),
      ]);
}

class _GapCard extends StatelessWidget {
  const _GapCard({required this.title, required this.body, required this.icon, required this.color});
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleIcon(icon: icon, color: color),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SoftText(body),
      ]));
}
