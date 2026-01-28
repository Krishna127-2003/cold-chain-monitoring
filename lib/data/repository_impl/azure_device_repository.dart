import '../models/registered_device.dart';
import '../repository/device_repository.dart';

abstract class AzureDeviceRepository implements DeviceRepository {
  static const String registerUrl = ""; // 🔴 paste later
  static const String listUrl = "";     // 🔴 paste later
  static const String deleteUrl = "";   // 🔴 paste later

  @override
  Future<bool> registerDevice(RegisteredDevice device) async {
    // 🔒 Flutter-side stub (ready for HTTP POST)
    // Will be implemented when Azure URL is provided
    throw UnimplementedError("Azure registerDevice not wired yet");
  }

  @override
  Future<List<RegisteredDevice>> getRegisteredDevices({
    required String email,
    required String loginType,
  }) async {
    // 🔒 Flutter-side stub (ready for HTTP GET)
    throw UnimplementedError("Azure getRegisteredDevices not wired yet");
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    // 🔒 Flutter-side stub (ready for HTTP DELETE)
    throw UnimplementedError("Azure deleteDevice not wired yet");
  }
}
