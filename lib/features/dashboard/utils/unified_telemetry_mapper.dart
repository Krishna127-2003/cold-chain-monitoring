  import 'dart:convert';
  import '../models/unified_telemetry.dart';
  import '../../../core/utils/log_safe.dart';

  class UnifiedTelemetryMapper {
  static bool bit(int v, int b) => ((v >> b) & 1) == 1;

  static UnifiedTelemetry? fromApi(Map<String, dynamic> raw) {

    logSafe("MAPPER RAW = $raw");
    logSafe("MAPPER latest_v = ${raw["latest_v"]}");
    logSafe("MAPPER latest_v TYPE = ${raw["latest_v"].runtimeType}");

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
      final isoParsed = DateTime.tryParse(raw);
      if (isoParsed != null) return isoParsed;

      final parts = raw.split(' ');
      if (parts.length != 2) return null;
      final d = parts[0].split('/');
      final t = parts[1].split(':');
      if (d.length != 3 || t.length != 3) return null;

      final year = int.tryParse(d[2]);
      final month = int.tryParse(d[1]);
      final day = int.tryParse(d[0]);
      final hour = int.tryParse(t[0]);
      final minute = int.tryParse(t[1]);
      final second = int.tryParse(t[2]);
      if ([year, month, day, hour, minute, second].contains(null)) {
        return null;
      }

      return DateTime(year!, month!, day!, hour!, minute!, second!);
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
