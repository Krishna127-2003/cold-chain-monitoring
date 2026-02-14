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
    print("🔄 Syncing from backend for $email");

    final backendRows = await UserInfoApi.fetchRegisteredDevices(email);
    if (backendRows.isEmpty) {
      print("ℹ️ Backend empty — nothing to sync");
      return true;
    }

    final localDevices =
        await (_deviceRepo as LocalDeviceRepository)
            .getDevicesForUser(email, loginType);

    final Map<String, RegisteredDevice> localMap = {
      for (var d in localDevices) d.deviceId: d
    };

    for (final row in backendRows) {
      final id = row["deviceId"]?.toString();
      if (id == null || id.isEmpty) continue;

      final existing = localMap[id];

      final device = RegisteredDevice(
        deviceId: id,
        qrCode: id,
        productKey: row["productKey"]?.toString() ??
            existing?.productKey ?? "SYNCED",
        serviceType: row["serviceType"]?.toString() ??
            existing?.serviceType ?? "UNKNOWN",
        email: email,
        loginType: loginType,
        registeredAt:
            DateTime.tryParse(row["registeredAt"] ?? "") ??
            existing?.registeredAt ??
            DateTime.now().toUtc(),

        displayName:
            row["displayName"]?.toString().isNotEmpty == true
                ? row["displayName"]
                : existing?.displayName ?? "Unnamed Device",

        department:
            row["department"]?.toString().isNotEmpty == true
                ? row["department"]
                : existing?.department ?? "Unknown Department",

        area:
            row["area"]?.toString().isNotEmpty == true
                ? row["area"]
                : existing?.area ?? "Unknown Area",

        pin:
            row["pin"]?.toString().isNotEmpty == true
                ? row["pin"]
                : existing?.pin ?? "0000",
      );

      await _deviceRepo.registerDevice(device);
    }

    print("✅ Safe backend merge complete");
    return true;

  } catch (e) {
    print("❌ Sync failed: $e");
    return false;
  }
}

}
