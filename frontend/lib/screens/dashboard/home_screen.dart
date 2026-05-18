
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
          padding: const EdgeInsets.all(22),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 720;
              final mobile = constraints.maxWidth < 430;
              final headline = 'Today, focus on ${data.weakTopic}';
              final subtitle =
                  'Hi $firstName. ${data.missionCourse} is in ${data.daysLeft} days, you are ${data.average}% ready, and your next best action is: ${data.nextBestAction}.';

              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: TextStyle(
                      fontSize: mobile ? 28 : 32,
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
                        icon: Icons.event_available_rounded,
                        label: '${data.daysLeft} days left',
                      ),
                      CalmPill(
                        icon: Icons.psychology_rounded,
                        label: data.emotionalTone.replaceAll('_', ' '),
                      ),
                      CalmPill(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Level ${data.level}',
                      ),
                      if (data.offline)
                        const CalmPill(
                          icon: Icons.offline_bolt_rounded,
                          label: 'Offline cache',
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MissionBars(data: data),
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
              );

              final mascot = StudentMascot(
                size: mobile ? 122 : 150,
                mood: MascotMood.celebrate,
              );

              return wide
                  ? Row(
                      children: [
                        Expanded(child: text),
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
          minWidth: 280,
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
              value: data.examRisk.toUpperCase(),
              subtitle: 'risk updates after every action',
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
        AcademicOSCommandStrip(data: data),
        const SizedBox(height: 16),
        NoteIntelligenceCard(notesCount: data.notes.length, onUpload: goLibrary),
      ],
    );
  }
}

class _MissionBars extends StatelessWidget {
  const _MissionBars({required this.data});
  final StudentSnapshot data;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('${data.streak}-day streak', .72),
      ('${data.average}% ready', data.average / 100),
      ('${data.daysLeft} days left', (1 - (data.daysLeft / 90)).clamp(.08, 1.0)),
      (data.examRisk, data.examRisk == 'low' ? .85 : data.examRisk == 'high' ? .32 : .58),
      ('Level ${data.level}', .64),
    ];
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 118, child: Text(item.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 9,
                      value: item.$2.clamp(0, 1),
                      color: CalmTheme.teal,
                      backgroundColor: CalmTheme.teal.withOpacity(.12),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class AcademicOSCommandStrip extends StatelessWidget {
  const AcademicOSCommandStrip({super.key, required this.data});
  final StudentSnapshot data;

  @override
  Widget build(BuildContext context) => SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleIcon(icon: Icons.dashboard_customize_rounded, color: CalmTheme.indigo),
                const SizedBox(width: 12),
                Expanded(child: Text('Academic OS status', style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 14),
            ResponsiveCalmGrid(
              minWidth: 180,
              spacing: 10,
              children: [
                _StatusTile(label: 'Exam north star', value: '${data.daysLeft} days', icon: Icons.event_available_rounded, color: CalmTheme.teal),
                _StatusTile(label: 'Weak area', value: data.weakTopic, icon: Icons.psychology_rounded, color: CalmTheme.orange),
                const _StatusTile(label: 'Memory loop', value: 'Reviews due', icon: Icons.style_rounded, color: CalmTheme.purple),
                _StatusTile(label: 'Support tone', value: data.emotionalTone.replaceAll('_', ' '), icon: Icons.favorite_rounded, color: CalmTheme.rose),
              ],
            ),
          ],
        ),
      );
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      );
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
