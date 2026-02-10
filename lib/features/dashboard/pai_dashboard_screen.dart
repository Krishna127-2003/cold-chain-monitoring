import 'base_dashboard_screen.dart';
import 'models/unified_telemetry.dart';
import 'package:flutter/material.dart';

class PaiDashboardScreen extends StatelessWidget {
  final String deviceId;

  const PaiDashboardScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    return BaseDashboardScreen(
      deviceId: deviceId,
      title: "PLATELET AGITATOR INCUBATOR",
      buildPills: (UnifiedTelemetry t) => [
        Pill("POWER", t.powerOn ? "ON" : "OFF"),
        Pill("BATTERY", "${t.battery}%"),
        Pill("ALARMS", t.alarm),
        Pill("PROBE", t.probeOk ? "OK" : "FAIL"),
      ],
    );
  }
}
