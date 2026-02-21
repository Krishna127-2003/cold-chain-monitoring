import '../models/unified_telemetry.dart';

class TelemetryStore {
  static final Map<String, UnifiedTelemetry> _cache = {};

  static UnifiedTelemetry? get(String deviceId) {
    return _cache[deviceId];
  }

  static void set(String deviceId, UnifiedTelemetry telemetry) {
    _cache[deviceId] = telemetry;
  }
}