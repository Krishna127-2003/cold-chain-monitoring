import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_result.dart';

class DeviceManagementApi {
  static const String _base =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/devices";

  static const Map<String, String> _headers = {
    "Content-Type": "application/json",
  };

  static const Duration _timeout = Duration(seconds: 8);
  static const int _maxRetries = 2;

  // =========================================================
  // CORE RESPONSE HANDLER
  // =========================================================

  static ApiResult _handle(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiResult(
          true,
          decoded["message"] ?? "Success",
        );
      }

      return ApiResult(
        false,
        decoded["error"] ?? "Operation failed",
      );
    } catch (_) {
      return ApiResult(false, "Invalid server response");
    }
  }

  // =========================================================
  // SMART POST WITH RETRY
  // =========================================================

  static Future<ApiResult> _post(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final res = await http
            .post(
              Uri.parse("$_base/$endpoint"),
              headers: _headers,
              body: jsonEncode(payload),
            )
            .timeout(_timeout);

        return _handle(res);
      } catch (_) {
        if (attempt == _maxRetries) {
          return ApiResult(
            false,
            "Network error. Please check your connection.",
          );
        }

        await Future.delayed(const Duration(seconds: 1));
      }
    }

    return ApiResult(false, "Unexpected error");
  }

  // =========================================================
  // REGISTER DEVICE
  // =========================================================

  static Future<ApiResult> registerDevice({
    required String email,
    required String deviceId,
    required String deviceProductKey,
    required String deviceName,
    required String deviceDisplayName,
    required String deviceDeptName,
    required String deviceAreaRoom,
    required String devicePin,
    required String deviceType,
  }) {
    return _post("register", {
      "email": email,
      "deviceId": deviceId,
      "deviceProductKey": deviceProductKey,
      "deviceName": deviceName,
      "deviceDisplayName": deviceDisplayName,
      "deviceDeptName": deviceDeptName,
      "deviceAreaRoom": deviceAreaRoom,
      "devicePin": devicePin,
      "deviceType": deviceType,
    });
  }

  // =========================================================
  // LIST DEVICES
  // =========================================================

  static Future<List<dynamic>> listDevices(String email) async {
    try {
      final res = await http
          .post(
            Uri.parse("$_base/list"),
            headers: _headers,
            body: jsonEncode({"email": email}),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) return [];

      final decoded = jsonDecode(res.body);
      return decoded["devices"] ?? [];
    } catch (_) {
      return [];
    }
  }

  // =========================================================
  // UPDATE DEVICE
  // =========================================================

  static Future<ApiResult> updateDevice({
    required String email,
    required String deviceId,
    required String devicePin,
    String? deviceName,
    String? deviceDisplayName,
    String? deviceDeptName,
    String? deviceAreaRoom,
    String? deviceType,
  }) {
    final payload = {
      "email": email,
      "deviceId": deviceId,
      "devicePin": devicePin,
      "deviceName": deviceName,
      "deviceDisplayName": deviceDisplayName,
      "deviceDeptName": deviceDeptName,
      "deviceAreaRoom": deviceAreaRoom,
      "deviceType": deviceType,
    }..removeWhere((_, v) => v == null);

    return _post("update", payload);
  }

  // =========================================================
  // DELETE DEVICE
  // =========================================================

  static Future<ApiResult> deleteDevice({
    required String email,
    required String deviceId,
    required String devicePin,
  }) {
    return _post("delete", {
      "email": email,
      "deviceId": deviceId,
      "devicePin": devicePin,
    });
  }
}
