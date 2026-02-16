  import 'dart:convert';
  import '../models/unified_telemetry.dart';
  import 'package:flutter/foundation.dart';


  class UnifiedTelemetryMapper {
  static bool bit(int v, int b) => ((v >> b) & 1) == 1;

  static UnifiedTelemetry? fromApi(Map<String, dynamic> raw) {

    debugPrint("MAPPER RAW = $raw");
    debugPrint("MAPPER latest_v = ${raw["latest_v"]}");
    debugPrint("MAPPER latest_v TYPE = ${raw["latest_v"].runtimeType}");

    dynamic latest = raw["latest_v"];
    if (latest == null) return null;

    if (latest is String) {
      latest = jsonDecode(latest);
    }

    if (latest is! Map<String, dynamic>) return null;

    final decoded = latest;

    final status = int.tryParse(decoded["status"]?.toString() ?? "0") ?? 0;

    double? d(v) => double.tryParse(v?.toString() ?? "");
    int i(v) => int.tryParse(v?.toString() ?? "") ?? 0;

    DateTime? parseTimestamp(String? raw) {
      if (raw == null) return null;

      final parts = raw.split(' ');
      final d = parts[0].split('/');
      final t = parts[1].split(':');

      return DateTime(
        int.parse(d[2]),
        int.parse(d[1]),
        int.parse(d[0]),
        int.parse(t[0]),
        int.parse(t[1]),
        int.parse(t[2]),
      );
    }

    return UnifiedTelemetry(
      deviceId: decoded["device_id"]?.toString() ?? "",
      timestamp: parseTimestamp(decoded["timestamp"]),

      pv: d(decoded["temp"]),
      sv: d(decoded["setv"]),

      powerOn: bit(status, 7),
      battery: i(decoded["battery"]),

      compressor: bit(status, 0),
      compressor1: bit(status, 0), // same for now
      compressor2: false,          // future expansion

      heater: bit(status, 1),
      agitator: false,             // only some devices use it
      defrost: false,

      probeOk: !bit(status, 3),

      alarm: decoded["ALARMS"]?.toString() ?? "NORMAL",

      logTime: parseTimestamp(decoded["log_time"]),

      // 🔥 REAL SYSTEM HEALTH
      systemHealthy: !bit(status, 12),
    );
  }
}