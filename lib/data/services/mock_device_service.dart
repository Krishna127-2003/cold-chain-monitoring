class MockDeviceService {
  // ✅ Dummy master registry (simulate Azure DeviceRegistry)
  // Later backend will validate from Azure Table Storage
  static const Map<String, String> _deviceRegistry = {
    "CB5191": "ETXSOBSOSF123214",
    "DF-002": "KEY-12345",
    "BBR-101": "KEY-5678",
    "PLT-777": "KEY-7777",
    "WIC-900": "KEY-9000",  
    "Device5192":"12345"
  };

  Future<Map<String, dynamic>> verifyDevice({
    required String deviceId,
    required String productKey,
    required String equipmentType,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate network delay

    final keyInRegistry = _deviceRegistry[deviceId];

    if (keyInRegistry == null) {
      return {
        "verified": false,
        "message": "Device ID not found in registry",
      };
    }

    if (keyInRegistry != productKey) {
      return {
        "verified": false,
        "message": "Invalid Product Key",
      };
    }

    return {
      "verified": true,
      "message": "Device verified successfully",
      "device": {
        "deviceId": deviceId,
        "equipmentType": equipmentType,
      }
    };
  }
}