import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/dashboard/models/unified_telemetry.dart';
import '../../features/dashboard/utils/unified_telemetry_mapper.dart';
import '../session/session_manager.dart';
import '../../features/notifications/alert_processor.dart';

class AndroidDataApi {
  static const String _baseUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/GetAndroidData";

  static final AlertProcessor _alertProcessor = AlertProcessor();

  /// ✅ Fetch unified telemetry (single clean object)
  static Future<UnifiedTelemetry?> fetchByDeviceId(String deviceId) async {
    final url = Uri.parse("$_baseUrl?device_id=$deviceId");

    debugPrint("📡 API CALL → $url");

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        debugPrint("❌ API ERROR ${response.statusCode}");
        return null;
      }

      final raw = jsonDecode(response.body);

      // 🎯 Convert once only
      final telemetry = UnifiedTelemetryMapper.fromApi(raw);

      if (telemetry == null) return null;

      // 🚨 Centralized alert processing
      if (telemetry.pv != null && telemetry.sv != null) {
        await _alertProcessor.process(
          pv: telemetry.pv!,
          sv: telemetry.sv!,
        );
      }

      // ⏱ Save last sync
      await SessionManager.saveLastSync(
        deviceId,
        DateTime.now().toUtc(),
      );

      debugPrint("✅ TELEMETRY OBJECT → ${telemetry.alarm}");

      return telemetry;
    } catch (e) {
      debugPrint("❌ API EXCEPTION $e");
      return null;
    }
  }
}
