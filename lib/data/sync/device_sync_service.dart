// ignore_for_file: avoid_print

import '../models/registered_device.dart';
import '../repository/device_repository.dart';
import '../repository_impl/local_device_repository.dart';
import '../api/user_info_api.dart';

class DeviceSyncService {
  static final DeviceRepository _deviceRepo = LocalDeviceRepository();

  /// 🔁 FULL backend → local resync (source of truth = backend)
  static Future<bool> syncFromBackend({
    required String email,
    required String loginType,
  }) async {
    try {
      print("🔄 Syncing devices for $email");

      /// 1️⃣ Fetch devices from backend
      /// 1️⃣ Fetch devices from backend
      final backendDevices =
          await UserInfoApi.fetchRegisteredDevices(email);

      print("📥 Backend returned ${backendDevices.length} devices");

      /// 2️⃣ If backend empty → DON'T wipe local cache
      if (backendDevices.isEmpty) {
        print("⚠️ Backend empty — not clearing local data");
        return false;
      }

      /// 3️⃣ Clear local cache safely
      await (_deviceRepo as LocalDeviceRepository).clearAllDevices();

      /// 3️⃣ Save fresh backend data locally
      for (final d in backendDevices) {
        final device = RegisteredDevice(
          deviceId: d["deviceId"].toString(),
          qrCode: d["deviceId"].toString(),
          productKey: d["productKey"]?.toString() ?? "SYNCED",
          serviceType: d["serviceType"].toString(),
          email: email,
          loginType: loginType,
          registeredAt: DateTime.parse(d["registeredAt"]),
          displayName: d["displayName"] ?? "Unnamed Device",
          department: d["department"] ?? "Unknown Department",
          area: d["area"] ?? "Unknown Area",
          pin: d["pin"] ?? "0000",
        );

        await _deviceRepo.registerDevice(device);
      }

      print("✅ Local device cache rebuilt");
      return true;

    } catch (e) {
      print("❌ Device sync failed: $e");
      return false;
    }
  }
}
