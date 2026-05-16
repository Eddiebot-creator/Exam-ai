import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SecureApiClient {
  SecureApiClient({required this.baseUrl});
  final String baseUrl;

  Future<String?> get _accessToken async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl$path'), headers: await _headers(), body: jsonEncode(body));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
