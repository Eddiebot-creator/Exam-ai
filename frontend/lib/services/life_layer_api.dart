
import 'dart:convert';
import 'package:http/http.dart' as http;

class LifeLayerApi {
  LifeLayerApi({required this.baseUrl});
  final String baseUrl;

  Future<Map<String, dynamic>> onboarding({
    required int userId,
    required String course,
    required String examDate,
    required String biggestStruggle,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/life-layer/onboarding'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'course': course,
        'exam_date': examDate,
        'biggest_struggle': biggestStruggle,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> emotionalState(int userId, {int wrongStreak = 0}) async {
    final res = await http.get(Uri.parse('$baseUrl/life-layer/emotional-state/$userId?wrong_streak=$wrongStreak'));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> diagnose(String topic, List<Map<String, dynamic>> answers) async {
    final res = await http.post(
      Uri.parse('$baseUrl/life-layer/diagnose'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'topic': topic, 'answers': answers}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
