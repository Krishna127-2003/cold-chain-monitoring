import 'dart:convert';
import 'package:http/http.dart' as http;

class UserActivityApi {
  static const String _url =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/userinfo";

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

    await http.post(
      Uri.parse(_url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
  }
}
