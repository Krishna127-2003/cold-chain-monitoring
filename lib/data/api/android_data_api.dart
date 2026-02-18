import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/dashboard/models/unified_telemetry.dart';
import '../../features/dashboard/utils/unified_telemetry_mapper.dart';
import '../session/session_manager.dart';

class AndroidDataApi {
  static const String _baseUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/GetAndroidData";


  /// ✅ Fetch unified telemetry (single clean object)
  static Future<UnifiedTelemetry?> fetchByDeviceId(String deviceId) async {
    final safeId = Uri.encodeQueryComponent(deviceId);
    final url = Uri.parse("$_baseUrl?device_id=$safeId");

    debugPrint("📡 API CALL → $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint("❌ API ERROR ${response.statusCode}");
        return null;
      }

      final raw = jsonDecode(response.body);
      if (raw is! Map<String, dynamic>) {
        debugPrint("❌ API RESPONSE FORMAT ERROR");
        return null;
      }

      debugPrint("RAW API RESPONSE = $raw");
      debugPrint("latest_v TYPE = ${raw["latest_v"].runtimeType}");

      // 🎯 Convert once only
      final telemetry = UnifiedTelemetryMapper.fromApi(raw);

      if (telemetry == null) return null;

      // 🚨 Centralized alert processing

      // ⏱ Save last sync
      unawaited(
        SessionManager.saveLastSync(
          deviceId,
          DateTime.now().toUtc(),
        ).catchError((_) {}),
      );

      debugPrint("✅ TELEMETRY OBJECT → ${telemetry.alarm}");

      return telemetry;
    } catch (e) {
      debugPrint("❌ API EXCEPTION $e");
      return null;
    }
  }
}
