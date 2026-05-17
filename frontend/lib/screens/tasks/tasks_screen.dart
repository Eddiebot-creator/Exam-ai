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
  List<bool> done = [];
  bool saving = false;
  List<String> get tasks => widget.data.missionTasks;
  int get completed => done.where((x) => x).length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTasks();
  }

  @override
  void didUpdateWidget(covariant TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTasks();
  }

  void _syncTasks() {
    if (done.length == tasks.length) return;
    done = List<bool>.filled(tasks.length, false);
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SectionIntro(icon: Icons.checklist_rounded, title: "Today's Plan", subtitle: widget.data.dailyMission['message']?.toString() ?? 'Your plan adapts from exam date, weak areas, quiz results, and review timing.', mascot: const StudentMascot(size: 100, mood: MascotMood.focus)),
    const SizedBox(height: 16),
    ResponsiveCalmGrid(minWidth: 260, children: [CalmMetric(title: 'Streak', value: '${widget.data.streak} days', subtitle: 'steady habit', icon: Icons.local_fire_department_rounded, color: CalmTheme.orange), CalmMetric(title: 'Level', value: '${widget.data.level}', subtitle: '${widget.data.xp + completed * 15} XP earned', icon: Icons.workspace_premium_rounded, color: CalmTheme.purple), CalmMetric(title: 'Today', value: '$completed / ${tasks.length}', subtitle: 'tasks completed', icon: Icons.check_circle_rounded, color: CalmTheme.green)]),
    const SizedBox(height: 16),
    SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var i = 0; i < tasks.length; i++) _TaskTile(number: i + 1, title: tasks[i], duration: _duration(tasks[i]), icon: _iconFor(tasks[i]), done: done[i], onTap: () => _toggleTask(i)), const SizedBox(height: 8), PrimaryCalmButton(label: saving ? 'Saving progress...' : "Save today's progress", icon: Icons.cloud_done_rounded, onTap: saving ? null : _saveProgress)])),
    const SizedBox(height: 16),
    SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Gamification, gently', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), const SoftText('XP, levels, streaks and badges motivate students without making the app noisy.'), const SizedBox(height: 14), Wrap(spacing: 10, runSpacing: 10, children: [CalmPill(icon: Icons.star_rounded, label: 'Quiz Master', onTap: () => showFeatureSheet(context, 'Quiz Master', 'Unlock by completing quizzes and improving your score.')), CalmPill(icon: Icons.local_fire_department_rounded, label: '7-day streak', onTap: () => showFeatureSheet(context, '7-day streak', 'Unlock by studying every day for one week.')), CalmPill(icon: Icons.auto_awesome_rounded, label: 'Focus Hero', onTap: () => showFeatureSheet(context, 'Focus Hero', 'Unlock by finishing daily plans consistently.'))])]))
  ]);

  void _toggleTask(int index) { setState(() => done[index] = !done[index]); if (done[index]) { showFeatureSheet(context, 'Task complete', 'Small win logged. Keep the rhythm gentle and steady.'); } else { toast(context, 'Task marked incomplete.'); } }
  String _duration(String task) {
    final match = RegExp(r'(\d+)\s*min').firstMatch(task.toLowerCase());
    return match == null ? '15 min' : '${match.group(1)} min';
  }
  IconData _iconFor(String task) {
    final lower = task.toLowerCase();
    if (lower.contains('quiz') || lower.contains('question') || lower.contains('mcq')) return Icons.quiz_rounded;
    if (lower.contains('flashcard') || lower.contains('review')) return Icons.style_rounded;
    if (lower.contains('ai') || lower.contains('explain')) return Icons.smart_toy_rounded;
    if (lower.contains('timed') || lower.contains('drill')) return Icons.timer_rounded;
    return Icons.menu_book_rounded;
  }
  Future<void> _saveProgress() async { setState(() => saving = true); try { final seconds = completed * 15 * 60; await widget.api.recordStudyTime(widget.userId, null, 'daily-plan:$completed/${tasks.length}:${widget.data.weakTopic}', seconds); await widget.api.learningEvent({'user_id': widget.userId, 'event_type': 'daily_plan', 'topic': widget.data.weakTopic, 'correct': completed == tasks.length, 'confidence': completed / tasks.length, 'difficulty': widget.data.dailyMission['difficulty'] ?? 'medium', 'seconds': seconds}); widget.onChanged(); if (mounted) showFeatureSheet(context, 'Progress saved', 'Your completed tasks, study time, streak, XP, readiness, and next review have been saved.'); } catch (e) { if (mounted) toast(context, 'Could not save progress: ${e.toString().replaceFirst('Exception: ', '')}'); } finally { if (mounted) setState(() => saving = false); } }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.number, required this.title, required this.duration, required this.icon, required this.done, required this.onTap});
  final int number; final String title; final String duration; final IconData icon; final bool done; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: done ? 1.02 : 1,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutBack,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: done ? CalmTheme.green : CalmTheme.teal.withOpacity(.12), borderRadius: BorderRadius.circular(8)),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: done ? const Icon(Icons.check_rounded, key: ValueKey('done'), color: Colors.white) : Center(key: const ValueKey('number'), child: Text('$number', style: const TextStyle(fontWeight: FontWeight.w900))),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(duration),
      trailing: AnimatedRotation(duration: const Duration(milliseconds: 220), turns: done ? .04 : 0, child: Icon(icon)),
      onTap: onTap,
    ),
  );
}
