// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/registered_device.dart';
import '../repository/device_repository.dart';
import '../api/user_activity_api.dart';
import '../session/session_manager.dart';

class LocalDeviceRepository implements DeviceRepository {
  static const _key = "registered_devices";

  @override
  Future<bool> registerDevice(RegisteredDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final email = await SessionManager.getEmail();

    if (email != null) {
      await UserActivityApi.sendAction(
        email: email,
        action: "device_added",
        deviceId: device.deviceId,
      );
    }

    // ✅ REMOVE duplicate deviceId (important)
    list.removeWhere((e) {
      final d = RegisteredDevice.fromJson(jsonDecode(e));
      return d.deviceId == device.deviceId;
    });

    list.add(jsonEncode(device.toJson()));
    await prefs.setStringList(_key, list);

    print("💾 DEVICE SAVED: ${device.deviceId}");
    return true;    
  }

  @override
  Future<List<RegisteredDevice>> getRegisteredDevices({
    required String email,
    required String loginType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    final all = list
        .map((e) => RegisteredDevice.fromJson(jsonDecode(e)))
        .toList();

    if (loginType == "guest") {
      return all.where((d) => d.loginType == "guest").toList();
    }

    return all.where((d) => d.email == email).toList();
  }

  @override
  Future<bool> hasAnyDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key);
    return list != null && list.isNotEmpty;
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    list.removeWhere((e) {
      final d = RegisteredDevice.fromJson(jsonDecode(e));
      return d.deviceId == deviceId;
    });

    await prefs.setStringList(_key, list);
  }

  Future<void> clearAllDevices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("registered_devices");
    print("🧹 Local device cache cleared");
  }

  Future<void> clearDevicesForUser(String email, String loginType) async {
    final devices = await getRegisteredDevices(
      email: email,
      loginType: loginType,
    );

    for (final d in devices) {
      await deleteDevice(d.deviceId);
    }
  }
}
