import 'dart:convert';
import 'package:http/http.dart' as http;

class AccountDeletionApi {
  static const String _baseUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/userinfo";

  /// Sends permanent delete command to backend
  static Future<bool> sendPermanentDeleteCommand(String email) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "action": "permanently_delete",
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
