import 'package:flutter/material.dart';
import '../../models/student_snapshot.dart';
import '../../services/api_client.dart';
import '../../theme/calm_theme.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mascot.dart';
import '../../widgets/soft_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.data, required this.api, required this.userId, required this.onChanged});
  final StudentSnapshot data;
  final ApiClient api;
  final int userId;
  final VoidCallback onChanged;
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<bool> done = [false, false, false, false];
  bool saving = false;
  final tasks = const [('Recap yesterday’s topic', '20 min', Icons.menu_book_rounded), ('Answer 10 practice MCQs', '15 min', Icons.quiz_rounded), ('Review one weak topic', '25 min', Icons.psychology_rounded), ('Ask AI for one explanation', '10 min', Icons.smart_toy_rounded)];
  int get completed => done.where((x) => x).length;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SectionIntro(icon: Icons.checklist_rounded, title: 'Today’s Plan', subtitle: 'Only four focused actions. Tap a task when you finish it and ExamAI saves your progress.', mascot: StudentMascot(size: 100, mood: MascotMood.focus)),
    const SizedBox(height: 16),
    ResponsiveCalmGrid(minWidth: 260, children: [CalmMetric(title: 'Streak', value: '${widget.data.streak} days', subtitle: 'steady habit', icon: Icons.local_fire_department_rounded, color: CalmTheme.orange), CalmMetric(title: 'Level', value: '${widget.data.level}', subtitle: '${widget.data.xp + completed * 15} XP earned', icon: Icons.workspace_premium_rounded, color: CalmTheme.purple), CalmMetric(title: 'Today', value: '$completed / ${tasks.length}', subtitle: 'tasks completed', icon: Icons.check_circle_rounded, color: CalmTheme.green)]),
    const SizedBox(height: 16),
    SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var i = 0; i < tasks.length; i++) _TaskTile(number: i + 1, title: tasks[i].$1, duration: tasks[i].$2, icon: tasks[i].$3, done: done[i], onTap: () => _toggleTask(i)), const SizedBox(height: 8), PrimaryCalmButton(label: saving ? 'Saving progress...' : 'Save today’s progress', icon: Icons.cloud_done_rounded, onTap: saving ? null : _saveProgress)])),
    const SizedBox(height: 16),
    SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Gamification, gently', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), const SoftText('XP, levels, streaks and badges motivate students without making the app noisy.'), const SizedBox(height: 14), Wrap(spacing: 10, runSpacing: 10, children: [CalmPill(icon: Icons.star_rounded, label: 'Quiz Master', onTap: () => showFeatureSheet(context, 'Quiz Master', 'Unlock by completing quizzes and improving your score.')), CalmPill(icon: Icons.local_fire_department_rounded, label: '7-day streak', onTap: () => showFeatureSheet(context, '7-day streak', 'Unlock by studying every day for one week.')), CalmPill(icon: Icons.auto_awesome_rounded, label: 'Focus Hero', onTap: () => showFeatureSheet(context, 'Focus Hero', 'Unlock by finishing daily plans consistently.'))])])),
  ]);

  void _toggleTask(int index) { setState(() => done[index] = !done[index]); toast(context, done[index] ? 'Task completed. Nice work.' : 'Task marked incomplete.'); }
  Future<void> _saveProgress() async { setState(() => saving = true); try { final seconds = completed * 15 * 60; await widget.api.recordStudyTime(widget.userId, null, 'daily-plan:$completed/${tasks.length}', seconds); widget.onChanged(); if (mounted) showFeatureSheet(context, 'Progress saved', 'Your completed tasks, study time, streak, and XP have been saved.'); } catch (e) { if (mounted) toast(context, 'Could not save progress: ${e.toString().replaceFirst('Exception: ', '')}'); } finally { if (mounted) setState(() => saving = false); } }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.number, required this.title, required this.duration, required this.icon, required this.done, required this.onTap});
  final int number; final String title; final String duration; final IconData icon; final bool done; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: done ? CalmTheme.green : CalmTheme.teal.withOpacity(.12), child: done ? const Icon(Icons.check_rounded, color: Colors.white) : Text('$number', style: const TextStyle(fontWeight: FontWeight.w900))), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(duration), trailing: Icon(icon), onTap: onTap);
}
