import 'package:flutter/material.dart';
import '../../models/student_snapshot.dart';
import '../../theme/calm_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.firstName, required this.data, required this.loading, required this.goTutor, required this.goTasks, required this.goLibrary, required this.goFocus});
  final String firstName;
  final StudentSnapshot data;
  final bool loading;
  final VoidCallback goTutor, goTasks, goLibrary, goFocus;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SoftCard(child: LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 720;
      final text = Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Today, focus on ${data.weakTopic}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.05)),
        const SizedBox(height: 8),
        SoftText('Hi $firstName — you’re ${data.average}% ready for ${data.missionCourse}. Complete 10 MCQs to improve your weak area.'),
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 10, children: [CalmPill(icon: Icons.local_fire_department_rounded, label: '${data.streak}-day streak'), CalmPill(icon: Icons.school_rounded, label: '${data.average}% ready'), CalmPill(icon: Icons.workspace_premium_rounded, label: 'Level ${data.level}')]),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: [PrimaryCalmButton(label: 'Continue studying', icon: Icons.play_arrow_rounded, onTap: goTasks), SecondaryCalmButton(label: 'Focus mode', icon: Icons.self_improvement_rounded, onTap: goFocus)]),
      ]));
      const mascot = StudentMascot(size: 150, mood: MascotMood.celebrate);
      return wide ? Row(children: [text, const ProgressRing(value: .74, label: '74%'), const SizedBox(width: 20), mascot]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [mascot, const SizedBox(height: 14), text]);
    })),
    const SizedBox(height: 16),
    ResponsiveCalmGrid(minWidth: 320, children: [StudyBrainCard(onStart: goTutor), DailyFlowCard(onStart: goTasks)]),
    const SizedBox(height: 16),
    ResponsiveCalmGrid(minWidth: 240, children: [CalmMetric(title: 'Today', value: '45 min', subtitle: 'recommended focus', icon: Icons.timer_rounded, color: CalmTheme.teal), CalmMetric(title: 'Exam readiness', value: '${data.average}%', subtitle: 'steady progress', icon: Icons.insights_rounded, color: CalmTheme.green), CalmMetric(title: 'XP', value: '${data.xp}', subtitle: 'keep building', icon: Icons.auto_awesome_rounded, color: CalmTheme.orange)]),
    const SizedBox(height: 16),
    NoteIntelligenceCard(notesCount: data.notes.length, onUpload: goLibrary),
  ]);
}

class StudyBrainCard extends StatelessWidget {
  const StudyBrainCard({super.key, required this.onStart});
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) => SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const CircleIcon(icon: Icons.psychology_rounded, color: CalmTheme.purple), const SizedBox(width: 12), Expanded(child: Text('AI Study Brain', style: Theme.of(context).textTheme.titleLarge))]), const SizedBox(height: 12), const SoftText('I remember weak topics, mistakes, and your preferred explanation style.'), const SizedBox(height: 14), PrimaryCalmButton(label: 'Ask my tutor', icon: Icons.chat_rounded, onTap: onStart, compact: true)]));
}

class DailyFlowCard extends StatelessWidget {
  const DailyFlowCard({super.key, required this.onStart});
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) {
    final tasks = const ['20 min recap', '10 MCQs', 'Weak topic review', 'AI explanation'];
    return SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const CircleIcon(icon: Icons.checklist_rounded, color: CalmTheme.teal), const SizedBox(width: 12), Expanded(child: Text('Today’s Flow', style: Theme.of(context).textTheme.titleLarge))]), const SizedBox(height: 12), for (var i = 0; i < tasks.length; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [CircleAvatar(radius: 13, backgroundColor: CalmTheme.teal.withOpacity(.12), child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))), const SizedBox(width: 10), Expanded(child: Text(tasks[i], style: const TextStyle(fontWeight: FontWeight.w700)))])), const SizedBox(height: 4), SecondaryCalmButton(label: 'View tasks', icon: Icons.arrow_forward_rounded, onTap: onStart)]));
  }
}

class NoteIntelligenceCard extends StatelessWidget {
  const NoteIntelligenceCard({super.key, required this.notesCount, required this.onUpload});
  final int notesCount;
  final VoidCallback onUpload;
  @override
  Widget build(BuildContext context) => SoftCard(child: Row(children: [const StudentMascot(size: 92, mood: MascotMood.focus), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Advanced Note Intelligence', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 6), SoftText(notesCount == 0 ? 'Upload one note and I’ll turn it into summaries, flashcards, quizzes, and study actions.' : 'You have $notesCount notes. Open your library to generate study materials.') ])), const SizedBox(width: 12), SecondaryCalmButton(label: 'Library', icon: Icons.folder_rounded, onTap: onUpload)]));
}
