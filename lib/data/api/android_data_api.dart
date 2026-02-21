import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/dashboard/storage/telemetry_store.dart';
import '../../features/dashboard/models/unified_telemetry.dart';
import '../../features/dashboard/utils/unified_telemetry_mapper.dart';
import '../session/session_manager.dart';
import '../../core/utils/log_safe.dart';
import '../../features/dashboard/datalogger/models/datalogger_telemetry.dart';
import '../../features/dashboard/datalogger/utils/datalogger_telemetry_mapper.dart';

class AndroidDataApi {
  static const String _baseUrl =
      "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/GetAndroidData";


  /// ✅ Fetch unified telemetry (single clean object)
  static Future<UnifiedTelemetry?> fetchByDeviceId(String deviceId) async {
    final safeId = Uri.encodeQueryComponent(deviceId);
    final url = Uri.parse("$_baseUrl?device_id=$safeId");

    logSafe("📡 API CALL → $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        logSafe("❌ API ERROR ${response.statusCode}");
        return null;
      }

      final raw = jsonDecode(response.body);
      if (raw is! Map<String, dynamic>) {
        logSafe("❌ API RESPONSE FORMAT ERROR");
        return null;
      }

      logSafe("RAW API RESPONSE = $raw");
      logSafe("latest_v TYPE = ${raw["latest_v"].runtimeType}");

      // 🎯 Convert once only
      final telemetry = UnifiedTelemetryMapper.fromApi(raw);

      if (telemetry == null) return null;

      TelemetryStore.set(deviceId, telemetry);

      // 🚨 Centralized alert processing

      // ⏱ Save last sync
      unawaited(
        SessionManager.saveLastSync(
          deviceId,
          DateTime.now().toUtc(),
        ).catchError((_) {}),
      );

      logSafe("✅ TELEMETRY OBJECT → ${telemetry.alarm}");

      return telemetry;
    } catch (e) {
      logSafe("❌ API EXCEPTION $e");
      return null;
    }
  }

  static Future<DataloggerTelemetry?> fetchDatalogger(String deviceId) async {
    final raw = await fetchRawByDeviceId(deviceId);

    if (raw == null) return null;

    return DataloggerTelemetryMapper.fromApi(raw);
  }

  static Future<Map<String, dynamic>?> fetchRawByDeviceId(String deviceId) async {
    final safeId = Uri.encodeQueryComponent(deviceId);
    final url = Uri.parse("$_baseUrl?device_id=$safeId");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final raw = jsonDecode(response.body);
      if (raw is! Map<String, dynamic>) return null;

      return raw;
    } catch (_) {
      return null;
    }
  }
}
