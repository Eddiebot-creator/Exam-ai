import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient(this.baseUrl);
  final String baseUrl;

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

  Map<String, dynamic> _map(http.Response response) {
    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) throw Exception(body['detail']?.toString() ?? 'Request failed (${response.statusCode}).');
    return body;
  }

  List<dynamic> _list(http.Response response) {
    if (response.statusCode >= 400) throw Exception('Request failed (${response.statusCode}).');
    return response.body.isEmpty ? [] : jsonDecode(response.body) as List<dynamic>;
  }
}
