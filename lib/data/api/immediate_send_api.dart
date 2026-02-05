// ignore_for_file: avoid_print

import 'package:http/http.dart' as http;

class ImmediateSendApi {

  static const String _baseUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/ImmediateSend";

  static Future<void> trigger({
    required int interval,
    required String deviceId,
  }) async {

    final url = Uri.parse("$_baseUrl?interval=$interval&device_id=$deviceId");

    try {
      final res = await http.get(url);

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
