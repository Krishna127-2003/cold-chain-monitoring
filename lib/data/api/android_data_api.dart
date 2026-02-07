import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/dashboard/utils/telemetry_parser.dart';
import '../session/session_manager.dart'; // ✅ ADD THIS
import '../../features/notifications/alert_processor.dart';

class AndroidDataApi {
  static const String _baseUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/GetAndroidData";

  static final AlertProcessor _alertProcessor = AlertProcessor();

  /// ✅ Fetch PARSED telemetry for ONE device
  static Future<Map<String, dynamic>?> fetchByDeviceId(String deviceId) async {
    final url = Uri.parse("$_baseUrl?device_id=$deviceId");

    debugPrint("📡 API CALL → $url");

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        debugPrint("❌ API ERROR ${response.statusCode}");
        return null;
      }

      final raw = jsonDecode(response.body);

      // 🔥 IMPORTANT PART
      final parsed = TelemetryParser.parse(raw);

      // 🚨 ALERT CHECK (production safe place)
      if (parsed.containsKey("temp") && parsed.containsKey("setv")) {
        await _alertProcessor.process(
          pv: (parsed["temp"] as num).toDouble(),
          sv: (parsed["setv"] as num).toDouble(),
        );
      }

      // ✅ SAVE LAST SYNC TIME HERE (VERY IMPORTANT)
      await SessionManager.saveLastSync(
        deviceId,
        DateTime.now().toUtc(),
      );

      debugPrint("✅ FLAT TELEMETRY → $parsed");

      return parsed; // ✅ NOT raw anymore
    } catch (e) {
      debugPrint("❌ API EXCEPTION $e");
      return null;
    }
  }
}