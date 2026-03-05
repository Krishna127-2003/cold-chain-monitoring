/// In-memory cache for datalogger sensor temps.
/// Updated whenever DataLoggerDashboardScreen fetches fresh data.
/// Read by AllDevicesScreen to show selected sensor values.
class DataloggerTempStore {
  static final Map<String, List<double?>> _cache = {};

  static void set(String deviceId, List<double?> temps) {
    _cache[deviceId] = List<double?>.from(temps);
  }

  static List<double?>? get(String deviceId) => _cache[deviceId];

  static void clear(String deviceId) => _cache.remove(deviceId);
}