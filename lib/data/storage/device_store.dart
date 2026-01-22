class DeviceStore {
  // Singleton instance
  static final DeviceStore instance = DeviceStore._internal();
  DeviceStore._internal();

  // In-memory store (for now)
  final List<Map<String, dynamic>> _devices = [];

  List<Map<String, dynamic>> getAllDevices() {
    return List.unmodifiable(_devices);
  }

  List<Map<String, dynamic>> getDevicesByType(String equipmentType) {
    return _devices
        .where((d) => d["equipmentType"] == equipmentType)
        .toList(growable: false);
  }

  void addDevice(Map<String, dynamic> device) {
    // Prevent duplicates by deviceId
    final existingIndex =
        _devices.indexWhere((d) => d["deviceId"] == device["deviceId"]);

    if (existingIndex != -1) {
      _devices[existingIndex] = device; // update existing
    } else {
      _devices.add(device);
    }
  }

  Map<String, dynamic>? getDeviceById(String deviceId) {
    try {
      return _devices.firstWhere((d) => d["deviceId"] == deviceId);
    } catch (_) {
      return null;
    }
  }
}
