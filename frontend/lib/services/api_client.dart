import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient(String baseUrl) : baseUrl = _normalizeBaseUrl(baseUrl);
  final String baseUrl;

  static String _normalizeBaseUrl(String value) {
    var next = value.trim();
    if (next.isEmpty) next = 'https://exam-ai-113m.onrender.com';
    if (!next.startsWith('http')) next = 'https://$next';
    while (next.endsWith('/')) {
      next = next.substring(0, next.length - 1);
    }
    return next;
  }

  Future<bool> ping() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/')).timeout(const Duration(seconds: 12));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(Uri.parse('$baseUrl/auth/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email.trim(), 'password': password})).timeout(const Duration(seconds: 35));
    return _map(response);
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(Uri.parse('$baseUrl/auth/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'full_name': name.trim(), 'email': email.trim(), 'password': password})).timeout(const Duration(seconds: 35));
    return _map(response);
  }

  Future<List<dynamic>> notes(int userId) async => _list(await http.get(Uri.parse('$baseUrl/notes?user_id=$userId')).timeout(const Duration(seconds: 25)));
  Future<List<dynamic>> history(int userId) async => _list(await http.get(Uri.parse('$baseUrl/quiz/history?user_id=$userId')).timeout(const Duration(seconds: 25)));
  Future<Map<String, dynamic>> progress(int userId) async => _map(await http.get(Uri.parse('$baseUrl/progress/$userId')).timeout(const Duration(seconds: 25)));
Future<Map<String, dynamic>> engineDashboard(int userId) async => _map(await http.get(Uri.parse('$baseUrl/engine/dashboard/$userId')).timeout(const Duration(seconds: 25)));
  Future<Map<String, dynamic>> healthDeep() async => _map(await http.get(Uri.parse('$baseUrl/health/deep')).timeout(const Duration(seconds: 25)));
  Future<Map<String, dynamic>> healthSchema() async => _map(await http.get(Uri.parse('$baseUrl/health/schema')).timeout(const Duration(seconds: 25)));

  Future<Map<String, dynamic>> createTextNote(int userId, String title, String text) async {
    final response = await http.post(Uri.parse('$baseUrl/notes/text'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user_id': userId, 'title': title, 'text': text})).timeout(const Duration(seconds: 40));
    return _map(response);
  }

  Future<Map<String, dynamic>> uploadFile(int userId, String title, PlatformFile file) async {
    if (file.path == null) throw Exception('File path not available.');
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/notes/upload'));
    request.fields['user_id'] = '$userId';
    request.fields['title'] = title;
    request.files.add(await http.MultipartFile.fromPath('file', file.path!));
    final streamed = await request.send().timeout(const Duration(seconds: 70));
    return _map(http.Response(await streamed.stream.bytesToString(), streamed.statusCode));
  }

  Future<Map<String, dynamic>> aiChat(int userId, int? noteId, String message) async {
    final path = '/ai/chat';
    final response = await http.post(Uri.parse('$baseUrl$path'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user_id': userId, 'note_id': noteId, 'message': message})).timeout(const Duration(seconds: 60));
    return _map(response);
  }

  Future<List<dynamic>> aiHistory(int userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/ai/history/$userId'))
        .timeout(const Duration(seconds: 25));
    return _list(response);
  }

  Future<Map<String, dynamic>> noteMaterials(int userId, int noteId) {
    return getJson('/notes/$noteId/materials?user_id=$userId');
  }

  Future<Map<String, dynamic>> regenerateNoteMaterials(int userId, int noteId) {
    return postJson('/notes/$noteId/regenerate', {'user_id': userId});
  }

  Future<Map<String, dynamic>> startQuiz(int userId, {int limit = 10, String mode = 'practice'}) {
    return getJson('/quiz/start/$userId?mode=$mode&limit=$limit');
  }

  Future<Map<String, dynamic>> submitQuiz(
    int userId,
    List<Map<String, dynamic>> answers, {
    String mode = 'practice',
    int secondsUsed = 0,
  }) {
    return postJson('/quiz/submit/$userId', {
      'mode': mode,
      'answers': answers,
      'seconds_used': secondsUsed,
    });
  }

  Future<Map<String, dynamic>> recordStudyTime(int userId, int? noteId, String activity, int seconds) async {
    final response = await http.post(Uri.parse('$baseUrl/progress/study-time'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user_id': userId, 'note_id': noteId, 'activity': activity, 'seconds': seconds})).timeout(const Duration(seconds: 25));
    return _map(response);
  }

  Future<Map<String, dynamic>> updateProfile(int userId, {String? fullName, String? email, String? avatarCharacter, String? bio}) async {
    final response = await http.put(Uri.parse('$baseUrl/profile/$userId'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({if (fullName != null) 'full_name': fullName.trim(), if (email != null) 'email': email.trim(), if (avatarCharacter != null) 'avatar_character': avatarCharacter, if (bio != null) 'bio': bio.trim()})).timeout(const Duration(seconds: 30));
    return _map(response);
  }

  Future<Map<String, dynamic>> changePassword(int userId, String currentPassword, String newPassword) async {
    final response = await http.put(Uri.parse('$baseUrl/profile/$userId/password'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'current_password': currentPassword, 'new_password': newPassword})).timeout(const Duration(seconds: 30));
    return _map(response);
  }

  Future<Map<String, dynamic>> uploadProfilePicture(int userId, PlatformFile file) async {
    if (file.path == null) throw Exception('File path not available.');
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/profile/$userId/picture'));
    request.files.add(await http.MultipartFile.fromPath('file', file.path!));
    final streamed = await request.send().timeout(const Duration(seconds: 60));
    return _map(http.Response(await streamed.stream.bytesToString(), streamed.statusCode));
  }

  Future<Map<String, dynamic>> completeOnboarding(
    int userId, {
    required String course,
    required String examDate,
    required String struggle,
    int targetScore = 80,
  }) async {
    final userResponse = await http.put(
      Uri.parse('$baseUrl/auth/onboarding/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'exam_course': course.trim(),
        'exam_date': examDate.trim(),
        'target_score': targetScore,
        'preferred_style': 'simple_analogy',
      }),
    ).timeout(const Duration(seconds: 30));
    final user = _map(userResponse);
    await postJson('/autonomous/onboarding', {
      'user_id': userId,
      'course': course.trim(),
      'struggle': struggle.trim(),
    });
    return user;
  }


Future<Map<String, dynamic>> getJson(String path) async {
  final response = await http
      .get(Uri.parse('$baseUrl$path'))
      .timeout(const Duration(seconds: 35));
  return _map(response);
}

Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
  final response = await http
      .post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 45));
  return _map(response);
}

Future<Map<String, dynamic>> adaptiveHome(int userId) async {
  return getJson('/autonomous/adaptive-home/$userId');
}

Future<Map<String, dynamic>> learningEvent(Map<String, dynamic> payload) async {
  return postJson('/autonomous/learning-event', payload);
}

Future<Map<String, dynamic>> nextBestAction(int userId) async {
  return getJson('/autonomous/next-best-action/$userId');
}

Future<List<dynamic>> studyRooms() async {
  final response = await http
      .get(Uri.parse('$baseUrl/study-rooms'))
      .timeout(const Duration(seconds: 25));
  return _list(response);
}

Future<Map<String, dynamic>> createStudyRoom(int userId, String name, String topic) {
  return postJson('/study-rooms', {
    'owner_id': userId,
    'name': name,
    'topic': topic,
  });
}

Future<Map<String, dynamic>> offlineQueue(int userId) {
  return getJson('/offline-sync/queue/$userId');
}

Future<Map<String, dynamic>> queueOfflineAction(int userId, String actionType, Map<String, dynamic> payload) {
  return postJson('/offline-sync/queue/$userId', {
    'action_type': actionType,
    'payload': payload,
  });
}

Future<Map<String, dynamic>> syncOfflineQueue(int userId) {
  return postJson('/offline-sync/sync/$userId', {});
}

Future<Map<String, dynamic>> createInstitutionCourse({
  required String courseCode,
  required String lecturer,
  required String title,
}) {
  return postJson('/institution/lecturer/course', {
    'course_code': courseCode,
    'lecturer': lecturer,
    'title': title,
    'materials': [],
  });
}

Future<Map<String, dynamic>> classInsights(String courseCode) {
  return getJson('/institution/class-insights/$courseCode');
}

Future<Map<String, dynamic>> exportMyData(int userId) {
  return getJson('/profile/$userId/export');
}

Future<Map<String, dynamic>> deleteMyLearningData(int userId) async {
  final response = await http
      .delete(Uri.parse('$baseUrl/profile/$userId/data'))
      .timeout(const Duration(seconds: 35));
  return _map(response);
}

  Map<String, dynamic> _map(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(_friendlyHttpError(response.statusCode, response.body));
    }
    if (response.statusCode >= 400) throw Exception(_friendlyBodyError(response.statusCode, body));
    return body;
  }

  List<dynamic> _list(http.Response response) {
    if (response.statusCode >= 400) throw Exception(_friendlyHttpError(response.statusCode, response.body));
    try {
      return response.body.isEmpty ? [] : jsonDecode(response.body) as List<dynamic>;
    } catch (_) {
      throw Exception(_friendlyHttpError(response.statusCode, response.body));
    }
  }

  String _friendlyBodyError(int statusCode, Map<String, dynamic> body) {
    final raw = body['detail'] ?? body['error'] ?? body['message'];
    final message = raw?.toString() ?? '';
    if (message.toLowerCase().contains('database') || message.toLowerCase().contains('schema')) {
      return 'The server is updating its database. Please try again in a minute.';
    }
    if (message.toLowerCase().contains('gemini') || message.toLowerCase().contains('api key')) {
      return 'The AI tutor is not fully connected yet. Check the AI key and try again.';
    }
    if (message.length > 180 || message.contains('Traceback') || message.contains('INSERT INTO') || message.contains('\\u000')) {
      return _fallbackMessage(statusCode);
    }
    return message.isEmpty ? _fallbackMessage(statusCode) : message;
  }

  String _friendlyHttpError(int statusCode, String body) {
    final text = body.trim();
    if (text.length > 180 || text.contains('Traceback') || text.contains('INSERT INTO') || text.contains('\\u000')) {
      return _fallbackMessage(statusCode);
    }
    return text.isEmpty ? _fallbackMessage(statusCode) : 'Server error ($statusCode): $text';
  }

  String _fallbackMessage(int statusCode) {
    if (statusCode == 413) return 'That file is too large. Try a smaller note or split it into parts.';
    if (statusCode == 401 || statusCode == 403) return 'Your session needs attention. Sign in again and retry.';
    if (statusCode >= 500) return 'The server had trouble completing that action. Please try again shortly.';
    return 'That action could not be completed. Please check the input and try again.';
  }
}
