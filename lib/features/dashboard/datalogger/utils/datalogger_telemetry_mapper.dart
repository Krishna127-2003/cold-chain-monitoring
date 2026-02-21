import 'dart:convert';
import '../models/datalogger_telemetry.dart';

class DataloggerTelemetryMapper {

  static DataloggerTelemetry? fromApi(Map<String, dynamic> decoded) {

    // ✅ backend sends latest_v as STRING
    final raw = decoded["latest_v"];
    if (raw == null) return null;

    // ✅ convert string → json
    final v = raw is String ? jsonDecode(raw) : raw;

    // ✅ fix timestamp format 20/02/2026 18:10:00 → DateTime
    DateTime? ts;
    try {
      final parts = (v["timestamp"] ?? "").split(" ");
      final d = parts[0].split("/");
      ts = DateTime.parse("${d[2]}-${d[1]}-${d[0]} ${parts[1]}");
    } catch (_) {}

    // ✅ load temp1 → temp16
    List<double?> temps = List.generate(
      16,
      (i) => double.tryParse(v["temp${i + 1}"]?.toString() ?? ""),
    );

    return DataloggerTelemetry(
      timestamp: ts,
      temps: temps,
    );
  }
}