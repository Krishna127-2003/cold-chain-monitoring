import '../api/user_info_api.dart';
import '../models/registered_device.dart';
import '../repository/device_repository.dart';
import '../repository_impl/local_device_repository.dart';

class DeviceSyncService {
  static final DeviceRepository _deviceRepo = LocalDeviceRepository();

  /// Backend is source of truth for registrations, with delete tombstones.
  static Future<bool> syncFromBackend({
    required String email,
    required String loginType,
  }) async {
    try {
      final backendRows = await UserInfoApi.fetchRegisteredDevices(email);
      final allRows = await UserInfoApi.fetchByEmail(email);

      DateTime? parseTs(Map<String, dynamic> row) {
        final candidates = [
          row['timestamp'],
          row['registeredAt'],
          row['log_time'],
        ];
        for (final v in candidates) {
          final t = DateTime.tryParse(v?.toString() ?? '');
          if (t != null) return t.toUtc();
        }
        return null;
      }

      final Map<String, DateTime?> latestRegistrationById = {};
      for (final row in backendRows) {
        final id = (row['deviceId'] ?? row['device_id'] ?? '').toString().trim();
        if (id.isEmpty) continue;
        final ts = parseTs(row);
        final prev = latestRegistrationById[id];
        if (prev == null || (ts != null && ts.isAfter(prev))) {
          latestRegistrationById[id] = ts;
        }
      }

      final Map<String, DateTime?> latestDeleteById = {};
      for (final row in allRows) {
        final type = row['type']?.toString();
        final action = row['action']?.toString();
        final isDelete = type == 'device_deleted' ||
            (type == 'user_activity' && action == 'device_deleted');
        if (!isDelete) continue;

        final id = (row['deviceId'] ?? row['device_id'] ?? '').toString().trim();
        if (id.isEmpty) continue;
        final ts = parseTs(row);
        final prev = latestDeleteById[id];
        if (prev == null || (ts != null && ts.isAfter(prev))) {
          latestDeleteById[id] = ts;
        }
      }

      bool shouldDelete(String id) {
        final deleteTs = latestDeleteById[id];
        if (deleteTs == null) return false;
        final registerTs = latestRegistrationById[id];
        if (registerTs == null) return true;
        return deleteTs.isAfter(registerTs);
      }

      final deletedDeviceIds = latestDeleteById.keys.where(shouldDelete).toSet();

      if (backendRows.isEmpty && deletedDeviceIds.isEmpty) {
        return true;
      }

      final localDevices = await _deviceRepo.getRegisteredDevices(
        email: email,
        loginType: loginType,
      );

      final Map<String, RegisteredDevice> localMap = {
        for (final d in localDevices) d.deviceId: d,
      };

      // Apply tombstones locally first so deleted devices do not reappear.
      for (final deletedId in deletedDeviceIds) {
        if (localMap.containsKey(deletedId)) {
          await _deviceRepo.deleteDevice(deletedId);
        }
      }

      for (final row in backendRows) {
        final id = (row['deviceId'] ?? row['device_id'] ?? '')
            .toString()
            .trim();
        if (id.isEmpty) continue;
        if (deletedDeviceIds.contains(id)) continue;

        final existing = localMap[id];
        final parsedRegisteredAt = parseTs(row);
        final rowPinHash = row['pinHash']?.toString() ?? '';
        final rowLegacyPin = row['pin']?.toString() ?? '';

        final device = RegisteredDevice(
          deviceId: id,
          qrCode: id,
          productKey:
              row['productKey']?.toString() ?? existing?.productKey ?? 'SYNCED',
          serviceType:
              row['serviceType']?.toString() ?? existing?.serviceType ?? 'UNKNOWN',
          email: email,
          loginType: loginType,
          registeredAt: parsedRegisteredAt ??
              existing?.registeredAt ??
              DateTime.now().toUtc(),
          displayName: row['displayName']?.toString().isNotEmpty == true
              ? row['displayName'].toString()
              : existing?.displayName ?? 'Unnamed Device',
          department: row['department']?.toString().isNotEmpty == true
              ? row['department'].toString()
              : existing?.department ?? 'Unknown Department',
          area: row['area']?.toString().isNotEmpty == true
              ? row['area'].toString()
              : existing?.area ?? 'Unknown Area',
          pinHash: rowPinHash.trim().isNotEmpty
              ? rowPinHash.trim()
              : rowLegacyPin.trim().isNotEmpty
                  ? rowLegacyPin.trim()
                  : existing?.pinHash ?? '',
          deviceNumber: row['deviceNumber'] != null
              ? int.tryParse(row['deviceNumber'].toString()) ??
                  existing?.deviceNumber ??
                  1
              : existing?.deviceNumber ?? 1,

          modeOp: "sync", // ✅ backend applied
        );

        await _deviceRepo.registerDevice(device);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
