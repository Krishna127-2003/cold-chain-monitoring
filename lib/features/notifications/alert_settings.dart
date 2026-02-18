import 'equipment_standards.dart';

class AlertSettings {
  // Temperature alerts
  bool highTempEnabled;
  double highTempThreshold;

  bool lowTempEnabled;
  double lowTempThreshold;

  // Battery
  bool batteryEnabled;
  int batteryBelowPercent;

  // Failures
  bool powerFailEnabled;
  bool probeFailEnabled;
  bool systemErrorEnabled;

  // Delay before firing alert
  Duration triggerDelay;

  AlertSettings({
    required this.highTempEnabled,
    required this.highTempThreshold,
    required this.lowTempEnabled,
    required this.lowTempThreshold,
    required this.batteryEnabled,
    required this.batteryBelowPercent,
    required this.powerFailEnabled,
    required this.probeFailEnabled,
    required this.systemErrorEnabled,
    required this.triggerDelay,
  });

  // ---------- DEFAULT SAFE VALUES ----------
  factory AlertSettings.defaultsForEquipment(String type) {
    final limits = EquipmentStandards.limitsFor(type);

    return AlertSettings(
      highTempEnabled: true,
      highTempThreshold: limits.max,

      lowTempEnabled: true,
      lowTempThreshold: limits.min,

      batteryEnabled: true,
      batteryBelowPercent: 25,

      powerFailEnabled: true,
      probeFailEnabled: true,
      systemErrorEnabled: true,

      triggerDelay: const Duration(minutes: 5),
    );
  }

  // ---------- JSON ----------
  Map<String, dynamic> toJson() => {
        "highTempEnabled": highTempEnabled,
        "highTempThreshold": highTempThreshold,
        "lowTempEnabled": lowTempEnabled,
        "lowTempThreshold": lowTempThreshold,
        "batteryEnabled": batteryEnabled,
        "batteryBelowPercent": batteryBelowPercent,
        "powerFailEnabled": powerFailEnabled,
        "probeFailEnabled": probeFailEnabled,
        "systemErrorEnabled": systemErrorEnabled,
        "triggerDelayMinutes": triggerDelay.inMinutes,
      };

  factory AlertSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AlertSettings.defaultsForEquipment("");

    return AlertSettings(
      highTempEnabled: json["highTempEnabled"] ?? true,
      highTempThreshold: (json["highTempThreshold"] ?? 8).toDouble(),

      lowTempEnabled: json["lowTempEnabled"] ?? true,
      lowTempThreshold: (json["lowTempThreshold"] ?? 2).toDouble(),

      batteryEnabled: json["batteryEnabled"] ?? true,
      batteryBelowPercent: json["batteryBelowPercent"] ?? 25,

      powerFailEnabled: json["powerFailEnabled"] ?? true,
      probeFailEnabled: json["probeFailEnabled"] ?? true,
      systemErrorEnabled: json["systemErrorEnabled"] ?? true,

      triggerDelay: Duration(
        minutes: json["triggerDelayMinutes"] ?? 5,
      ),
    );
  }
}
