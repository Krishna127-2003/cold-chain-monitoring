import 'dart:convert';
import 'package:http/http.dart' as http;

class AndroidDataApi {
  static const String _baseUrl =
      "https://datapanel-40-h0gec0bvh4g7fage.canadacentral-01.azurewebsites.net/api/GetAndroidData";
  //// "https://{BBR}{QRCODE}-{UserEnteredKey}}.canadacentral-01.azurewebsites.net/api/GetAndroidData";
  static Future<Map<String, dynamic>?> fetchLatest() async {
    try {
      final res = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(res.body);

      // ✅ If API returns direct object map
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      // ✅ If API returns list (take first record)
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return Map<String, dynamic>.from(decoded.first);
      }

      return null;
    } catch (e) {
      // ✅ Prevent crash always
      return null;
    }
  }
}
