
import 'dart:convert';
import 'package:http/http.dart' as http;

class LiveAiService {
  static const String baseUrl =
      "https://exam-ai-113m.onrender.com";

  Future<String> askTutor(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': 1,
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['answer'] ?? 'No answer returned';
    }

    return 'AI request failed';
  }
}
