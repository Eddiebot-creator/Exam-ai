
import 'package:flutter/material.dart';
import '../../models/student_snapshot.dart';
import '../../theme/calm_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.firstName,
    required this.data,
    required this.loading,
    required this.goTutor,
    required this.goTasks,
    required this.goLibrary,
    required this.goFocus,
  });

  final String firstName;
  final StudentSnapshot data;
  final bool loading;
  final VoidCallback goTutor, goTasks, goLibrary, goFocus;

  @override
  Widget build(BuildContext context) {
    // Uses the latest StudentSnapshot, which is refreshed after adaptive events.
    // Backend /autonomous/adaptive-home can now feed this snapshot through your dashboard loader.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SoftCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 720;
              final headline = 'Today, focus on ${data.weakTopic}';
              final subtitle =
                  'Hi $firstName — ExamAI is adapting your study flow automatically. You are ${data.average}% ready for ${data.missionCourse}.';

              final text = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SoftText(subtitle),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        CalmPill(
                          icon: Icons.local_fire_department_rounded,
                          label: '${data.streak}-day streak',
                        ),
                        CalmPill(
                          icon: Icons.school_rounded,
                          label: '${data.average}% ready',
                        ),
                        CalmPill(
                          icon: Icons.psychology_rounded,
                          label: 'Adaptive mission',
                        ),
                        CalmPill(
                          icon: Icons.workspace_premium_rounded,
                          label: 'Level ${data.level}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        PrimaryCalmButton(
                          label: 'Start adaptive mission',
                          icon: Icons.play_arrow_rounded,
                          onTap: goTasks,
                        ),
                        SecondaryCalmButton(
                          label: 'Ask AI coach',
                          icon: Icons.smart_toy_rounded,
                          onTap: goTutor,
                        ),
                        SecondaryCalmButton(
                          label: 'Focus mode',
                          icon: Icons.self_improvement_rounded,
                          onTap: goFocus,
                        ),
                      ],
                    ),
                  ],
                ),
              );

              const mascot = StudentMascot(
                size: 150,
                mood: MascotMood.celebrate,
              );

              return wide
                  ? Row(
                      children: [
                        text,
                        ProgressRing(value: data.average / 100, label: '${data.average}%'),
                        const SizedBox(width: 20),
                        mascot,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        mascot,
                        const SizedBox(height: 14),
                        text,
                      ],
                    );
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
            CalmMetric(
              title: 'Today',
              value: 'Adaptive',
              subtitle: 'changes after every action',
              icon: Icons.auto_graph_rounded,
              color: CalmTheme.teal,
            ),
            CalmMetric(
              title: 'Exam readiness',
              value: '${data.average}%',
              subtitle: 'updates from your performance',
              icon: Icons.insights_rounded,
              color: CalmTheme.green,
            ),
            CalmMetric(
              title: 'XP',
              value: '${data.xp}',
              subtitle: 'earned from real events',
              icon: Icons.auto_awesome_rounded,
              color: CalmTheme.orange,
            ),
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
  Widget build(BuildContext context) => SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleIcon(icon: Icons.psychology_rounded, color: CalmTheme.teal),
            const SizedBox(height: 12),
            Text('AI Study Brain', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const SoftText(
              'ExamAI now learns from quiz attempts, tutor chats, study time, weak topics, and emotional signals.',
            ),
            const SizedBox(height: 16),
            PrimaryCalmButton(
              label: 'Open tutor',
              icon: Icons.arrow_forward_rounded,
              onTap: onStart,
            ),
          ],
        ),
      );
}

class DailyFlowCard extends StatelessWidget {
  const DailyFlowCard({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleIcon(icon: Icons.task_alt_rounded, color: CalmTheme.green),
            const SizedBox(height: 12),
            Text('Autonomous Daily Flow', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const SoftText(
              'Every wrong answer can now adjust difficulty, tutor style, spaced repetition, readiness and next mission.',
            ),
            const SizedBox(height: 16),
            SecondaryCalmButton(
              label: 'View tasks',
              icon: Icons.checklist_rounded,
              onTap: onStart,
            ),
          ],
        ),
      );
}

class NoteIntelligenceCard extends StatelessWidget {
  const NoteIntelligenceCard({
    super.key,
    required this.notesCount,
    required this.onUpload,
  });

  final int notesCount;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) => SoftCard(
        child: Row(
          children: [
            const CircleIcon(icon: Icons.upload_file_rounded, color: CalmTheme.indigo),
            const SizedBox(width: 12),
            Expanded(
              child: SoftText(
                notesCount == 0
                    ? 'Upload notes so ExamAI can personalize tutor explanations, quizzes, flashcards and exam prediction.'
                    : '$notesCount notes are feeding the adaptive study brain.',
              ),
            ),
            const SizedBox(width: 12),
            SecondaryCalmButton(
              label: 'Library',
              icon: Icons.folder_rounded,
              onTap: onUpload,
            ),
          ],
        ),
      );
}
