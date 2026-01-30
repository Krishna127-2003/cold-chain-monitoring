// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class GetEmailDataApi {
  static const String _baseUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/GetEmailData";

  static Future<List<Map<String, dynamic>>> fetchDevices(
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
      }
    } catch (e) {
      print("⚠️ GetEmailData error: $e");
    }

    return [];
  }
}
