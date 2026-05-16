
import 'dart:convert';
import 'package:http/http.dart' as http;

class IntelligenceApi {
  IntelligenceApi({required this.baseUrl});
  final String baseUrl;

  Future<Map<String, dynamic>> getDailyMission(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/intelligence/daily-mission/$userId'));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdaptiveQuizPlan(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/intelligence/adaptive-quiz-plan/$userId'));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateTimetable(int userId, List<Map<String, dynamic>> courses) async {
    final res = await http.post(
      Uri.parse('$baseUrl/intelligence/timetable'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'courses': courses, 'days': 7}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> calculateGpa(List<Map<String, dynamic>> courses) async {
    final res = await http.post(
      Uri.parse('$baseUrl/intelligence/gpa'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'courses': courses}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> examCountdown(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/intelligence/exam-countdown/$userId'));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
