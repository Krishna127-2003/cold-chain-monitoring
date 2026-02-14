// ignore_for_file: avoid_print

import '../models/registered_device.dart';
import '../repository/device_repository.dart';
import '../repository_impl/local_device_repository.dart';
import '../api/user_info_api.dart';

class DeviceSyncService {
  static final DeviceRepository _deviceRepo = LocalDeviceRepository();

  /// 🔁 Backend = source of truth
  static Future<bool> syncFromBackend({
    required String email,
    required String loginType,
  }) async {
    try {
      print("🔄 Starting backend sync for $email");

      final backendRows =
          await UserInfoApi.fetchRegisteredDevices(email);

      if (backendRows.isEmpty) {
        print("ℹ️ No backend devices found — keeping local cache");
        return true; // valid state (user just has no devices yet)
      }

      /// ✅ Build unique devices by deviceId
      final Map<String, Map<String, dynamic>> unique = {};

      for (final row in backendRows) {
        final id = row["deviceId"]?.toString();
        if (id != null && id.isNotEmpty) {
          unique[id] = row;
        }
      }

      print("📦 Unique backend devices: ${unique.length}");

      /// 🧹 Clear only this user's local devices
      await (_deviceRepo as LocalDeviceRepository)
          .clearDevicesForUser(email, loginType);

      /// 💾 Rebuild local cache
      for (final d in unique.values) {
        final device = RegisteredDevice(
          deviceId: d["deviceId"].toString(),
          qrCode: d["deviceId"].toString(),
          productKey: d["productKey"]?.toString() ?? "SYNCED",
          serviceType: d["serviceType"].toString(),
          email: email,
          loginType: loginType,
          registeredAt: DateTime.tryParse(d["registeredAt"] ?? "") ??
              DateTime.now().toUtc(),
          displayName: d["displayName"] ?? "Unnamed Device",
          department: d["department"] ?? "Unknown Department",
          area: d["area"] ?? "Unknown Area",
          pin: d["pin"] ?? "0000",
        );

        await _deviceRepo.registerDevice(device);
      }

      print("✅ Backend sync complete");
      return true;

    } catch (e) {
      print("❌ Sync failed: $e");
      return false;
    }
  }
}
