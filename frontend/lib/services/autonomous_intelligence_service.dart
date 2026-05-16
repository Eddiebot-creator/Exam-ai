
import 'api_client.dart';

class AutonomousIntelligenceService {
  AutonomousIntelligenceService({required this.api, required this.userId});

  final ApiClient api;
  final int userId;

  Future<Map<String, dynamic>> loadAdaptiveHome() {
    return api.adaptiveHome(userId);
  }

  Future<Map<String, dynamic>> recordQuizResult({
    required String topic,
    required bool correct,
    required double confidence,
    required String difficulty,
    required int seconds,
    String gapType = 'conceptual',
  }) {
    return api.learningEvent({
      'user_id': userId,
      'event_type': correct ? 'quiz_correct' : 'quiz_failed',
      'topic': topic,
      'correct': correct,
      'confidence': confidence,
      'difficulty': difficulty,
      'seconds': seconds,
      'gap_type': gapType,
    });
  }

  Future<Map<String, dynamic>> recordStudySession({
    required String topic,
    required int seconds,
  }) {
    return api.learningEvent({
      'user_id': userId,
      'event_type': 'study_session',
      'topic': topic,
      'correct': true,
      'confidence': 0.55,
      'difficulty': 'medium',
      'seconds': seconds,
    });
  }

  Future<Map<String, dynamic>> nextBestAction() {
    return api.nextBestAction(userId);
  }
}
