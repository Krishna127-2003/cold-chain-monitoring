import 'package:shared_preferences/shared_preferences.dart';

class SelectedSensorsStorage {
  static String _key(String deviceId) => 'selected_sensors_$deviceId';

  /// Save up to 2 selected sensor indices (0-based)
  static Future<void> save(String deviceId, List<int> indices) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = indices.take(2).toList();
    await prefs.setString(_key(deviceId), trimmed.join(','));
  }

  /// Load selected sensor indices (0-based). Returns empty list if none saved.
  static Future<List<int>> load(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(deviceId));
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }

  static Future<void> clear(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(deviceId));
  }
}