class TelemetryMapper {
  static String formatValue(String key, dynamic value) {
    final v = value.toString().trim();

    if (v.isEmpty) return "--";

    switch (key.toLowerCase()) {
      case "pv":
      case "sv":
        return "$v°C";

      case "compressor":
      case "heater":
      case "agitator":
      case "defrost":
        return v == "1" ? "ON" : "OFF";

      case "door":
        return v == "1" ? "OPEN" : "CLOSED";

      case "probe":
      case "power":
        return v == "1" ? "OK" : "FAIL";

      case "battery":
        return "$v%";

      default:
        return v;
    }
  }

  static bool isGood(String key, String value) {
    switch (key.toLowerCase()) {
      case "compressor":
      case "agitator":
        return value == "ON";

      case "heater":
      case "defrost":
        return value == "OFF";

      case "door":
        return value == "CLOSED";

      case "probe":
      case "power":
        return value == "OK";

      default:
        return true;
    }
  }

  static String prettifyKey(String key) {
    return key
        .replaceAll("_", " ")
        .split(" ")
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(" ");
  }
}
