// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class UserInfoApi {
  static const String _baseUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/userinfo";

  /// =========================
  /// 🔹 SAVE (POST)
  /// Used for:
  /// - Google login
  /// - Guest login
  /// - Device registration (optional)
  /// =========================
  static Future<bool> postData(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        print("✅ userinfo POST success");
        return true;
      } else {
        print("⚠️ userinfo POST failed: ${res.body}");
      }
    } catch (e) {
      print("❌ userinfo POST error: $e");
    }
    return false;
  }

  static Future<bool> sendUserInfo({
    required String email,
    required String loginType,
  }) {
    return postData({
      "email": email,
      "loginType": loginType,
      "timestamp": DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// =========================
  /// 🔹 READ (GET)
  /// Used for:
  /// - Sync devices
  /// - Restore user session
  /// =========================
  static Future<List<Map<String, dynamic>>> fetchByEmail(
      String email) async {
    final uri = Uri.parse("$_baseUrl?email=$email");

    try {
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }

        if (decoded is Map) {
          return [Map<String, dynamic>.from(decoded)];
        }
      } else {
        print("⚠️ userinfo GET failed: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ userinfo GET error: $e");
    }

    return [];
  }
}
