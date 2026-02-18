// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;
import '../storage/secure_store.dart';

class ImmediateSendApi {
  static final SecureStore _secureStore = SecureStore();

  static const String _baseUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/ImmediateSend";

  static Future<void> trigger(String deviceId) async {

    final url = Uri.parse(_baseUrl).replace(queryParameters: {
      "device_id": deviceId,
    });

    try {
      final headers = <String, String>{};
      final token = await _secureStore.getToken();
      if (token != null && token.trim().isNotEmpty) {
        headers["Authorization"] = "Bearer ${token.trim()}";
      }

      final res = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        print("⚡ Live data triggered for device $deviceId");
      } else {
        print("⚠️ ImmediateSend failed: ${res.statusCode}");
      }
    } catch (e) {
      print("⚠️ ImmediateSend error: $e");
    }
  }
}
