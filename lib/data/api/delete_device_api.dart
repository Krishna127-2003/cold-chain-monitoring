import 'dart:convert';
import 'package:http/http.dart' as http;

class DeleteDeviceApi {
  static const _url =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/DeleteDevice";

  static Future<bool> deleteDevice({
    required String email,
    required String deviceId,
  }) async {
    final res = await http.post(
      Uri.parse(_url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "deviceId": deviceId,
      }),
    );

    return res.statusCode == 200;
  }
}
