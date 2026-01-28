import 'dart:convert';
import 'package:http/http.dart' as http;

class DeviceRegisterApi {
  // 🔴 PLACEHOLDER — paste Azure URL later
  static const String _registerDeviceUrl =
      "https://YOUR_AZURE_API/api/RegisterDevice";

  /// Registers a device in backend
  /// Returns true if backend accepted, false otherwise
  static Future<bool> registerDevice({
    required String email,
    required String loginType, // google | guest
    required String deviceId,
    required String qrCode,
    required String productKey,
    required String serviceType,
  }) async {
    try {
      final payload = {
        "email": email,
        "loginType": loginType,
        "deviceId": deviceId,
        "qrCode": qrCode,
        "productKey": productKey,
        "serviceType": serviceType,
        "platform": "flutter",
        "registeredAt": DateTime.now().toUtc().toIso8601String(),
      };

      final res = await http.post(
        Uri.parse(_registerDeviceUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      // ❗ Backend not available → fail silently
      return false;
    }
  }
}
