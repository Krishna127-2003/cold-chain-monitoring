import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'alert_settings.dart';

class AlertSettingsStorage {
  static String _key(String? deviceId) {
    final id = deviceId?.trim();
    if (id == null || id.isEmpty) return "alert_settings_global";
    return "alert_settings_$id";
  }

  // ---------------- SAVE ----------------
  static Future<void> save({
    required AlertSettings settings,
    String? deviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(deviceId);

    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(key, jsonString);
  }

  // ---------------- LOAD ----------------
  static Future<AlertSettings> load({
    required String deviceId,
    required String equipmentType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(deviceId);

    final jsonString = prefs.getString(key);

    if (jsonString == null) {
      return AlertSettings.defaultsForEquipment(equipmentType);
    }

    try {
      final decoded = jsonDecode(jsonString);
      return AlertSettings.fromJson(decoded);
    } catch (_) {
      // corrupted storage fallback
      return AlertSettings.defaultsForEquipment(equipmentType);
    }
  }
}
