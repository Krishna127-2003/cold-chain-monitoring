import 'dart:convert';
import 'package:http/http.dart' as http;

class DeviceCallbackApi {
  /// 🔴 Callback URL (Vinay provided)
  static const String _callbackUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/ESP32"
      "?code=G-w0L6ka-84rQiDKkT0WJ663zbGRxTm_42Yzx9ztIaH-AzFush7Zrg==";

  static Future<void> sendDeviceData({
    required String deviceId,
    required int temperature,
    required double humidity,
    required int compressor,
    required int defrost,
    required int door,
    required int power,
    required int battery,
  }) async {
    final url = Uri.parse(_callbackUrl);

    final payload = {
      "DeviceId": deviceId,
      "Temperature": temperature,
      "Humidity": humidity,
      "Compressor": compressor,
      "Defrost": defrost,
      "Door": door,
      "Power": power,
      "Battery": battery,
      "Timestamp": DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final response = await http.post(
        url,
        headers: const {
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("✅ Callback sent successfully");
      } else {
        print(
            "❌ Callback failed (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      print("⚠️ Callback error: $e");
    }
  }
}
