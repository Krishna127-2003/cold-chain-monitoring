import 'package:shared_preferences/shared_preferences.dart';

class SensorNameStorage {

  static String _key(String deviceId, int index) =>
      "sensor_${deviceId}_$index";

  static Future<String> getName(String deviceId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(deviceId, index)) ?? "Temp Sensor $index";
  }

  static Future<void> setName(
      String deviceId,
      int index,
      String name,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(deviceId, index), name);
  }
}