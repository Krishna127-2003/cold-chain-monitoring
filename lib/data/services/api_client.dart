import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/env.dart';

class ApiClient {
  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final url = Uri.parse("${Env.baseUrl}$path");

    final headers = <String, String>{
      "Content-Type": "application/json",
    };

    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    } else {
      // standard error
      throw Exception(decoded["message"] ?? "Something went wrong");
    }
  }
}
