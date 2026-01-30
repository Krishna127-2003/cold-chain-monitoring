// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class DeviceRegistrationApi {
  /// 🔴 Vinay’s Azure Function URL (CALLBACK)
  static const String _registerUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/ESP32"
      "?code=G-w0L6ka-84rQiDKkT0WJ663zbGRxTm_42Yzx9ztIaH-AzFush7Zrg==";

  static Future<void> registerDevice({
    required String email,
    required String loginType, // google | guest
    required String deviceId,
    required String qrCode,
    required String productKey,
    required String serviceType,
    required DateTime registeredAt,
  }) async {
    final payload = {
      "email": email,
      "loginType": loginType,
      "deviceId": deviceId,
      "qrCode": qrCode,
      "productKey": productKey,
      "serviceType": serviceType,
      "registeredAt": registeredAt.toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse(_registerUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        // ❌ Do NOT crash app
        // ❌ Do NOT block user
        print("⚠️ Azure registration failed: ${response.body}");
      } else {
        print("✅ Device registration sent to Azure");
      }
    } catch (e) {
      // ❌ Network failure should never break UX
      print("⚠️ Azure registration error: $e");
    }
  }
}
