import '../models/registered_device.dart';

abstract class DeviceRepository {
  Future<bool> registerDevice(RegisteredDevice device);

  Future<List<RegisteredDevice>> getRegisteredDevices({
    required String email,
    required String loginType,
  });

  Future<void> deleteDevice(String deviceId);

  /// 🔥 Splash ONLY uses this
  Future<bool> hasAnyDevice();
}
