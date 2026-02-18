import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_store.dart';

class UserInfoApi {
  static const String _baseUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/userinfo";

  static final SecureStore _secureStore = SecureStore();

  // ================= HEADERS =================

  static Future<Map<String, String>> _jsonHeaders() async {
    final headers = <String, String>{
      "Content-Type": "application/json",
    };

    final token = await _secureStore.getToken();
    if (token != null && token.trim().isNotEmpty) {
      headers["Authorization"] = "Bearer ${token.trim()}";
    }

    return headers;
  }

  // ================= BASE POST =================

  static Future<bool> postData(Map<String, dynamic> payload) async {
    try {
      final res = await http
          .post(
            Uri.parse(_baseUrl),
            headers: await _jsonHeaders(),
            body: jsonEncode({
              ...payload,
              "timestamp": DateTime.now().toUtc().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ================= LOGIN =================

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

  // ================= DEVICE REGISTER =================

  static Future<bool> sendDeviceRegistration({
    required String email,
    required String loginType,
    required String deviceId,
    required String qrCode,
    required String productKey,
    required String serviceType,
    required String displayName,
    required String department,
    required String area,
    required String pinHash,

    // ✅ SERIAL + OPERATION MODE
    required int deviceNumber,
    required String modeOp,
  }) {
    return postData({
      "type": "device_registration",

      "email": email,
      "loginType": loginType,

      "deviceId": deviceId,
      "qrCode": qrCode,
      "productKey": productKey,
      "serviceType": serviceType,

      "displayName": displayName,
      "department": department,
      "area": area,
      "pinHash": pinHash.trim(),

      // ✅ NEW FIELDS (Task 14 correct)
      "deviceNumber": deviceNumber,
      "modeOp": modeOp,
    });
  }

  // ================= ACCOUNT DELETE =================

  static Future<bool> sendPermanentDelete({
    required String email,
  }) {
    return postData({
      "type": "permanent_delete",
      "email": email,
      "command": "permanently_delete",
    });
  }

  // ================= FETCH =================

  static Future<List<Map<String, dynamic>>> fetchByEmail(String email) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {"email": email},
    );

    try {
      final res = await http
          .get(
            uri,
            headers: await _jsonHeaders(),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return [];

      final decoded = jsonDecode(res.body);

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (decoded is Map) {
        return [Map<String, dynamic>.from(decoded)];
      }
    } catch (_) {}

    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchRegisteredDevices(
    String email,
  ) async {
    final rows = await fetchByEmail(email);

    return rows.where((r) => r["type"] == "device_registration").toList();
  }

  // ================= EXISTS =================

  static Future<bool> doesUserExist(String email) async {
    final rows = await fetchByEmail(email);
    return rows.isNotEmpty;
  }
}
