  import 'dart:convert';
  import '../models/unified_telemetry.dart';

  class UnifiedTelemetryMapper {
    static UnifiedTelemetry? fromApi(Map<String, dynamic> raw) {
      final latest = raw["latest_v"];
      if (latest == null || latest is! String) return null;

      final decoded = jsonDecode(latest);
      final status = int.tryParse(decoded["status"]?.toString() ?? "0") ?? 0;
      bool isSystemError = (status & (1 << 12)) != 0;


      double? d(v) => double.tryParse(v?.toString() ?? "");
      int i(v) => int.tryParse(v?.toString() ?? "") ?? 0;
      bool b(v) => v?.toString() == "1";
      

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

        powerOn: b(decoded["pwron"]),
        battery: i(decoded["battery"]),

        compressor1: b(decoded["compressor1"]),
        compressor2: b(decoded["compressor2"]),
        compressor: b(decoded["compressor"]),

        heater: b(decoded["heater"]),
        agitator: b(decoded["agitator"]),
        defrost: b(decoded["defrost"]),

        probeOk: b(decoded["probe"]),

        alarm: decoded["ALARMS"]?.toString() ?? "NORMAL",
        logTime: parseTimestamp(decoded["log_time"]),

        systemHealthy: !isSystemError,
      );
    }
  }
