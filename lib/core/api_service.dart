import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const Duration requestTimeout = Duration(seconds: 3);

  static Future<Map<String, dynamic>> get(String path) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(requestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('API 요청 실패: ${response.statusCode}');
  }
}
