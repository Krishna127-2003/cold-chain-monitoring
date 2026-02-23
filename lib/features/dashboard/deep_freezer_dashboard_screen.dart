import 'base_dashboard_screen.dart';
import 'models/unified_telemetry.dart';
import 'package:flutter/material.dart';

class DeepFreezerDashboardScreen extends StatelessWidget {
  final String deviceId;

  const DeepFreezerDashboardScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    return BaseDashboardScreen(
      deviceId: deviceId,
      equipmentType: "DEEP_FREEZER",
      title: "DEEP FREEZER -40°C",
      buildPills: (UnifiedTelemetry t) => [
        Pill("POWER", t.powerOn ? "ON" : "OFF"),
        Pill("BATTERY", "${t.battery}%"),
        Pill("COMPRESSOR", t.compressor ? "ON" : "OFF"),
        Pill("ALARMS", t.alarm),
        Pill("PROBE", t.probeOk ? "OK" : "FAIL"),
      ],
    );
  }
}
