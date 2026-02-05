// ignore_for_file: avoid_print

import 'dart:convert';

class TelemetryParser {
  static Map<String, dynamic> parse(Map<String, dynamic> raw) {
    final Map<String, dynamic> out = {};

    // 1️⃣ Copy top-level fields (device_id etc)
    raw.forEach((k, v) {
      if (k != "latest_v") {
        out[k] = v;
      }
    });

    // 2️⃣ Extract latest_v (JSON STRING)
    final latestV = raw["latest_v"];
    if (latestV == null || latestV is! String || latestV.isEmpty) {
      return out;
    }

    try {
      // 3️⃣ Decode JSON inside string
      final decoded = jsonDecode(latestV);

      if (decoded is Map<String, dynamic>) {
        decoded.forEach((k, v) {
          out[k] = v;
        });
      }
    } catch (e) {
      // ❌ Do not crash app
      print("❌ TelemetryParser JSON error: $e");
    }

    return out;
  }
}
