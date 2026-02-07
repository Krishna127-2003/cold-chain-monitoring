import 'dart:convert';
import '../models/unified_telemetry.dart';

class UnifiedTelemetryMapper {
  static UnifiedTelemetry? fromApi(Map<String, dynamic> raw) {
    final latest = raw["latest_v"];
    if (latest == null || latest is! String) return null;

    final decoded = jsonDecode(latest);

    double? d(v) => double.tryParse(v?.toString() ?? "");
    int i(v) => int.tryParse(v?.toString() ?? "") ?? 0;
    bool b(v) => v?.toString() == "1";

    DateTime? parseTime(String? t) {
      if (t == null) return null;
      final p = t.split(' ');
      final dmy = p[0].split('/');
      final hms = p[1].split(':');
      return DateTime(
        int.parse(dmy[2]),
        int.parse(dmy[1]),
        int.parse(dmy[0]),
        int.parse(hms[0]),
        int.parse(hms[1]),
        int.parse(hms[2]),
      );
    }

    return UnifiedTelemetry(
      deviceId: decoded["device_id"]?.toString() ?? "",
      timestamp: parseTime(decoded["timestamp"]),

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
    );
  }
}
