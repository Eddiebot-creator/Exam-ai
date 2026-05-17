import 'dart:math';

class StudentSnapshot {
  StudentSnapshot({
    required this.notes,
    required this.history,
    required this.progress,
    required this.user,
    this.adaptive = const {},
    this.offline = false,
  });
  final List<dynamic> notes;
  final List<dynamic> history;
  final Map<String, dynamic> progress;
  final Map<String, dynamic> user;
  final Map<String, dynamic> adaptive;
  final bool offline;

  int get average => (adaptive['readiness'] as num?)?.toInt() ?? (progress['average_score'] as num?)?.toInt() ?? 76;
  int get streak => (progress['streak_days'] as num?)?.toInt() ?? 7;
  int get minutes => ((progress['study_seconds'] as num?)?.toInt() ?? 7200) ~/ 60;
  int get level => max(1, (minutes / 60).floor() + 1);
  int get xp => min(980, minutes * 4 + history.length * 25);
  String get weakTopic {
    final weakTopics = progress['weak_topics'];
    final fallback = weakTopics is List && weakTopics.isNotEmpty ? weakTopics.first.toString() : 'Recursion';
    return adaptive['focus_topic']?.toString() ?? fallback;
  }
  String get missionCourse {
    final adaptiveCourse = adaptive['course']?.toString() ?? '';
    final userCourse = user['exam_course']?.toString() ?? '';
    if (adaptiveCourse.isNotEmpty) return adaptiveCourse;
    if (userCourse.isNotEmpty) return userCourse;
    return 'CSC301';
  }
  int get daysLeft => (adaptive['days_left'] as num?)?.toInt() ?? 23;
  String get nextBestAction => adaptive['next_best_action']?.toString() ?? 'Start your adaptive mission';
  String get emotionalTone => adaptive['emotional_tone']?.toString() ?? 'encouraging';
  String get examRisk => adaptive['exam_risk']?.toString() ?? 'normal';
  Map<String, dynamic> get dailyMission => (adaptive['daily_mission'] as Map?)?.cast<String, dynamic>() ?? {};
  List<String> get missionTasks => ((dailyMission['tasks'] as List?) ?? const ['Study your weak topic for 25 minutes', 'Complete 10 adaptive MCQs', 'Review due flashcards']).map((item) => item.toString()).toList();
}
