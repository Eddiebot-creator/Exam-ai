
// Paste these INSIDE class ApiClient, before _map().

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
