// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class UserInfoApi {
  static const String _baseUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/userinfo";

  // ============================
  // 🔹 GENERIC POST
  // Used for:
  // - login
  // - device_registration
  // - permanent_delete (future)
  // ============================
  static Future<bool> postData(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          ...payload,
          "timestamp": DateTime.now().toUtc().toIso8601String(),
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("✅ userinfo POST success → ${payload["type"] ?? "login"}");
        return true;
      } else {
        print("⚠️ userinfo POST failed: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("❌ userinfo POST error: $e");
    }
    return false;
  }

  // ============================
  // 🔐 LOGIN EVENT
  // ============================
  static Future<bool> sendUserLogin({
    required String email,
    required String loginType,
  }) {
    return postData({
      "type": "login",
      "email": email,
      "loginType": loginType,
    });
  }

  // ============================
  // 📦 DEVICE REGISTRATION EVENT
  // ============================
  static Future<bool> sendDeviceRegistration({
    required String email,
    required String loginType,
    required String deviceId,
    required String qrCode,
    required String productKey,
    required String serviceType,
  }) {
    return postData({
      "type": "device_registration",
      "email": email,
      "loginType": loginType,
      "deviceId": deviceId,
      "qrCode": qrCode,
      "productKey": productKey,
      "serviceType": serviceType,
    });
  }

  // ============================
  // 🧨 PERMANENT DELETE (future)
  // ============================
  static Future<bool> sendPermanentDelete({
    required String email,
  }) {
    return postData({
      "type": "permanent_delete",
      "email": email,
      "command": "permanently_delete",
    });
  }

  // ============================
  // 📥 READ ALL USER ROWS
  // (login + devices + future events)
  // ============================
  static Future<List<Map<String, dynamic>>> fetchByEmail(String email) async {
    final uri = Uri.parse("$_baseUrl?email=$email");

    try {
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }

        if (decoded is Map) {
          // backend still broken → wrap for safety
          print("⚠️ Backend returned single row instead of full history");
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

  // ============================
// 📥 FETCH ONLY REGISTERED DEVICES
// ============================
  static Future<List<Map<String, dynamic>>> fetchRegisteredDevices(
      String email) async {
    final uri = Uri.parse("$_baseUrl?email=$email");

    try {
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        print("⚠️ Device fetch failed: ${res.statusCode}");
        return [];
      }

      final decoded = jsonDecode(res.body);

      List<Map<String, dynamic>> rows = [];

      if (decoded is List) {
        rows = List<Map<String, dynamic>>.from(decoded);
      } else if (decoded is Map) {
        rows = [Map<String, dynamic>.from(decoded)];
      }

      // 🔥 FILTER ONLY device_registration rows
      final devices = rows.where((row) {
        return row["type"] == "device_registration";
      }).toList();

      print("📦 Found ${devices.length} registered devices for $email");

      return devices;

    } catch (e) {
      print("❌ fetchRegisteredDevices error: $e");
      return [];
    }
  }
  static Future<bool> doesUserExist(String email) async {
    final rows = await fetchByEmail(email);
    return rows.isNotEmpty;
  }
}
