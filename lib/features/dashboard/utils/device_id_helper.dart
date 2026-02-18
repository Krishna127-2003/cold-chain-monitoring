class DeviceIdHelper {
  static String? normalize(String raw) {
    final value = raw.trim();

    // If it's URL — extract device_id
    try {
      final uri = Uri.tryParse(value);
      if (uri != null && uri.queryParameters.containsKey("device_id")) {
        final id = uri.queryParameters["device_id"];
        if (id != null && id.isNotEmpty) return id;
      }
    } catch (_) {}

    // If numeric — accept directly
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return value;
    }
    return null; // invalid input
  }
}
