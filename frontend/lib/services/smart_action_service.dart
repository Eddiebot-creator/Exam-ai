
import 'api_client.dart';

class SmartActionResult {
  SmartActionResult({required this.title, required this.message, this.data});
  final String title;
  final String message;
  final Map<String, dynamic>? data;
}

class SmartActionService {
  SmartActionService({required this.api, required this.userId});
  final ApiClient api;
  final int userId;

  Future<SmartActionResult> explainLike12({int? noteId}) async {
    final res = await api.aiChat(userId, noteId,
        'Explain this like I am 12 using my notes, weak topics, simple examples, and one exam-style question.');
    return SmartActionResult(title: 'Simple Explanation', message: _answer(res), data: res);
  }

  Future<SmartActionResult> adaptiveMcqs({int? noteId}) async {
    final plan = await api.getJson('/intelligence/adaptive-quiz-plan/$userId');
    final res = await api.aiChat(userId, noteId,
        'Generate 5 adaptive MCQs using this plan: $plan. Include answers and explanations.');
    return SmartActionResult(title: 'Adaptive MCQs', message: _answer(res), data: res);
  }

  Future<SmartActionResult> summarizeNote({int? noteId}) async {
    final res = await api.aiChat(userId, noteId,
        'Summarize my latest uploaded note. Include key points, exam areas, and flashcards.');
    return SmartActionResult(title: 'Smart Summary', message: _answer(res), data: res);
  }

  Future<SmartActionResult> examTips({int? noteId}) async {
    final countdown = await api.getJson('/intelligence/exam-countdown/$userId');
    final mission = await api.getJson('/intelligence/daily-mission/$userId');
    final res = await api.aiChat(userId, noteId,
        'Give exam tips using this countdown: $countdown and mission: $mission.');
    return SmartActionResult(title: 'Exam Strategy', message: _answer(res), data: res);
  }

  Future<SmartActionResult> dailyMission() async {
    final data = await api.getJson('/intelligence/daily-mission/$userId');
    final tasks = ((data['tasks'] as List?) ?? []).map((e) => '• $e').join('\n');
    return SmartActionResult(
      title: data['title']?.toString() ?? 'Today’s Mission',
      message: '${data['message'] ?? ''}\n\nCourse: ${data['course']}\nDays left: ${data['days_left']}\nReadiness: ${data['readiness']}%\n\n$tasks',
      data: data,
    );
  }

  Future<SmartActionResult> spacedReview() async {
    final data = await api.postJson('/intelligence/spaced-review', {
      'correct': true,
      'confidence': 0.5,
      'ease': 2.5,
    });
    return SmartActionResult(
      title: 'Spaced Review',
      message: 'Next review: ${data['next_review_at']}\nInterval: ${data['interval_days']} day(s)',
      data: data,
    );
  }

  Future<SmartActionResult> timetable() async {
    final data = await api.postJson('/intelligence/timetable', {
      'user_id': userId,
      'days': 7,
      'courses': [
        {'course': 'CSC301', 'topics': ['Recursion', 'Trees', 'Graphs']}
      ],
    });
    return SmartActionResult(
      title: 'Generated Timetable',
      message: ((data['plan'] as List?) ?? [])
          .map((d) => 'Day ${d['day']}: ${d['course']} — ${d['focus']}')
          .join('\n'),
      data: data,
    );
  }

  Future<SmartActionResult> curriculum() async {
    final data = await api.postJson('/intelligence/curriculum', {
      'school': 'Nigerian university',
      'course': 'CSC301',
      'weak_topics': ['Recursion', 'Graphs', 'Trees'],
    });
    return SmartActionResult(
      title: 'Curriculum Recommendation',
      message: data.toString(),
      data: data,
    );
  }

  String _answer(Map<String, dynamic> res) =>
      res['answer']?.toString() ??
      res['response']?.toString() ??
      res['message']?.toString() ??
      'No response returned.';
}
