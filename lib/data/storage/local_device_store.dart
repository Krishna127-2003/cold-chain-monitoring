import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDeviceStore {
  static const String _key = "saved_devices_v1";

  /// ✅ In-memory cache (fast UI)
  static List<Map<String, dynamic>> _devices = [];

  /// ✅ Call this ONCE in app start (main.dart) before UI
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      _devices = [];
      return;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    _devices = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static List<Map<String, dynamic>> getDevices({String? equipmentType}) {
    if (equipmentType == null) {
      return List<Map<String, dynamic>>.from(_devices);
    }

    return _devices
        .where((d) => d["equipmentType"] == equipmentType)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> addDevice(Map<String, dynamic> device) async {
    _devices.add(device);
    await _save();
  }

  static Future<void> deleteDevice({
    required String equipmentType,
    required String deviceId,
  }) async {
    _devices.removeWhere((d) =>
        d["equipmentType"] == equipmentType && d["deviceId"] == deviceId);

    await _save();
  }

  static Future<void> deleteMany({
    required String equipmentType,
    required List<String> deviceIds,
  }) async {
    _devices.removeWhere((d) =>
        d["equipmentType"] == equipmentType &&
        deviceIds.contains((d["deviceId"] ?? "").toString()));

    await _save();
  }

  /// ✅ Deletes device from ALL types (global delete)
  static Future<void> deleteDeviceGlobal({required String deviceId}) async {
    _devices.removeWhere(
      (d) => (d["deviceId"] ?? "").toString() == deviceId,
    );

    await _save();
  }

  static Future<void> clearAll() async {
    _devices.clear();
    await _save();
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_devices));
  }
}
