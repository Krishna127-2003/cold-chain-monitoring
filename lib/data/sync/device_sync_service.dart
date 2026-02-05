// ignore_for_file: avoid_print

import '../models/registered_device.dart';
import '../repository/device_repository.dart';
import '../repository_impl/local_device_repository.dart';
import '../api/user_info_api.dart';


class DeviceSyncService {
  static final DeviceRepository _deviceRepo = LocalDeviceRepository();

  /// Sync backend devices → local storage
  static Future<bool> syncFromBackend({
    required String email,
    required String loginType,
  }) async {
    try {
      final backendDevices = await UserInfoApi.fetchByEmail(email);

      if (backendDevices.isEmpty) {
        print("ℹ️ No backend devices for $email");
        return false;
      }

      for (final device in backendDevices) {
        print("📦 Backend row raw: $device");

        // ✅ 1. Only accept DEVICE rows
        if (device["type"] != "device_registration") {
          print("⏭️ Skipping non-device row");
          continue;
        }

        // ✅ 2. Guard against corrupt rows
        final deviceId = device["deviceId"];
        if (deviceId == null || deviceId.toString().isEmpty) {
          print("⚠️ Skipping device with null deviceId");
          continue;
        }

        final registeredDevice = RegisteredDevice(
          deviceId: deviceId.toString(),
          qrCode: device["qrCode"]?.toString() ?? deviceId.toString(),
          productKey: device["productKey"]?.toString() ?? "SYNCED",
          serviceType: device["serviceType"]?.toString() ?? "UNKNOWN",
          email: email,
          loginType: loginType,
          registeredAt: device["registeredAt"] != null
              ? DateTime.parse(device["registeredAt"].toString())
              : DateTime.now(),
        );

        await _deviceRepo.registerDevice(registeredDevice);
      }


      print("✅ Synced ${backendDevices.length} devices from backend");
      return true;
    } catch (e) {
      print("❌ Device sync failed: $e");
      return false;
    }
  }
}
