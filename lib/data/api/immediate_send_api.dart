// ignore_for_file: avoid_print

import 'package:http/http.dart' as http;

class ImmediateSendApi {
  static const String _url =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/ImmediateSend?interval=19";

  static Future<void> trigger({required int interval}) async {
    try {
      final res = await http.get(Uri.parse(_url));

      if (res.statusCode == 200) {
        print("⚡ ImmediateSend triggered");
      } else {
        print("⚠️ ImmediateSend failed: ${res.statusCode}");
      }
    } catch (e) {
      print("⚠️ ImmediateSend error: $e");
    }
  }
}
