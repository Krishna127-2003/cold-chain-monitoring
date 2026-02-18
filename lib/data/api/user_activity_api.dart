import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_store.dart';

class UserActivityApi {
  static const String _url =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/userinfo";
  static final SecureStore _secureStore = SecureStore();

  static Future<void> sendAction({
    required String email,
    required String action,
    String? deviceId,
    String? command,
  }) async {
    final body = {
      "type": "user_activity",
      "email": email,
      "action": action,
      "deviceId": deviceId,
      "command": command,
      "timestamp": DateTime.now().toIso8601String(),
    };

    try {
      final headers = <String, String>{"Content-Type": "application/json"};
      final token = await _secureStore.getToken();
      if (token != null && token.trim().isNotEmpty) {
        headers["Authorization"] = "Bearer ${token.trim()}";
      }
      await http
          .post(
            Uri.parse(_url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Activity logging must never block user flows.
    }
  }
}
