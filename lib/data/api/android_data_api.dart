import 'dart:convert';
import 'package:http/http.dart' as http;

class AndroidDataApi {
  // API
  static const String _baseUrl =
      "https://panelapp2-czh4c2euawgkd6d6.centralindia-01.azurewebsites.net/api/GetAndroidData";

  /// ✅ Fetch latest data from backend
  static Future<Map<String, dynamic>?> fetchLatest() async {
    try {
      final res = await http.get(Uri.parse(_baseUrl));

      if (res.statusCode != 200) return null;

      final decoded = jsonDecode(res.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
