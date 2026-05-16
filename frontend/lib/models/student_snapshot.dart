import 'dart:math';

class StudentSnapshot {
  StudentSnapshot({required this.notes, required this.history, required this.progress, required this.user});
  final List<dynamic> notes;
  final List<dynamic> history;
  final Map<String, dynamic> progress;
  final Map<String, dynamic> user;

  int get average => (progress['average_score'] as num?)?.toInt() ?? 76;
  int get streak => (progress['streak_days'] as num?)?.toInt() ?? 7;
  int get minutes => ((progress['study_seconds'] as num?)?.toInt() ?? 7200) ~/ 60;
  int get level => max(1, (minutes / 60).floor() + 1);
  int get xp => min(980, minutes * 4 + history.length * 25);
  String get weakTopic => progress['weak_topic']?.toString() ?? 'Recursion';
  String get missionCourse => progress['course']?.toString() ?? 'CSC301';
}
