// ignore_for_file: avoid_print

import '../api/get_email_data_api.dart';
import '../models/registered_device.dart';
import '../repository/device_repository.dart';
import '../repository_impl/local_device_repository.dart';

class DeviceSyncService {
  static final DeviceRepository _deviceRepo = LocalDeviceRepository();

  /// Sync backend devices → local storage
  static Future<bool> syncFromBackend({
    required String email,
    required String loginType,
  }) async {
    try {
      final backendDevices = await GetEmailDataApi.fetchDevices(email);

      if (backendDevices.isEmpty) {
        print("ℹ️ No backend devices for $email");
        return false;
      }

      for (final device in backendDevices) {
        // 🔍 DEBUG: see raw backend payload
        print("📦 Backend device raw: $device");

        final registeredDevice = RegisteredDevice(
          deviceId: device["deviceId"].toString(),
          qrCode: device["qrCode"]?.toString() ?? device["deviceId"].toString(),
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
