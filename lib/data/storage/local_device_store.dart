import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDeviceStore {
  static const String _key = "saved_devices_v1";

  static List<Map<String, dynamic>> _devices = [];

  static String _extractId(Map<String, dynamic> d) {
    return (d["deviceId"] ??
            d["id"] ??
            d["device_id"] ??
            d["deviceID"] ??
            "")
        .toString()
        .trim();
  }

  static String _extractType(Map<String, dynamic> d) {
    return (d["equipmentType"] ?? "").toString().trim();
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      _devices = [];
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _devices = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      _devices = [];
      await prefs.remove(_key);
    }
  }

  static Future<bool> hasAnyDevices() async {
    await init(); // ensures SharedPreferences loaded
    return _devices.isNotEmpty;
  }

  static List<Map<String, dynamic>> getDevices({String? equipmentType}) {
    if (equipmentType == null) {
      return List<Map<String, dynamic>>.from(_devices);
    }

    final type = equipmentType.trim();

    return _devices
        .where((d) => _extractType(d) == type)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> addDevice(Map<String, dynamic> device) async {
    final newId = _extractId(device);

    // ✅ prevent duplicates by same deviceId inside same equipmentType
    if (newId.isNotEmpty) {
      final newType = _extractType(device);

      _devices.removeWhere((d) {
        final oldId = _extractId(d);
        final oldType = _extractType(d);
        return oldId == newId && oldType == newType;
      });
    }

    _devices.add(device);
    await _save();
  }

  static Future<void> deleteDevice({
    required String equipmentType,
    required String deviceId,
  }) async {
    final type = equipmentType.trim();
    final id = deviceId.trim();

    _devices.removeWhere((d) {
      final dType = _extractType(d);
      final dId = _extractId(d);
      return dType == type && dId == id;
    });

    await _save();
  }

  static Future<void> deleteMany({
    required String equipmentType,
    required List<String> deviceIds,
  }) async {
    final type = equipmentType.trim();
    final ids = deviceIds.map((e) => e.trim()).toSet();

    _devices.removeWhere((d) {
      final dType = _extractType(d);
      final dId = _extractId(d);
      return dType == type && ids.contains(dId);
    });

    await _save();
  }

  static Future<void> deleteDeviceGlobal({required String deviceId}) async {
    final id = deviceId.trim();

    _devices.removeWhere((d) => _extractId(d) == id);

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