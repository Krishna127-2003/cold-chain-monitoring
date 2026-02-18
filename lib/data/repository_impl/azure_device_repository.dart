import '../models/registered_device.dart';
import '../repository/device_repository.dart';

abstract class AzureDeviceRepository implements DeviceRepository {
  static const String registerUrl = ""; // 🔴 paste later
  static const String listUrl = "";     // 🔴 paste later
  static const String deleteUrl = "";   // 🔴 paste later

  @override
  Future<bool> registerDevice(RegisteredDevice device) async {
    return false;
  }

  @override
  Future<List<RegisteredDevice>> getRegisteredDevices({
    required String email,
    required String loginType,
  }) async {
    return const [];
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    return;
  }
}
