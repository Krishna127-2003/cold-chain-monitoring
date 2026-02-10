import 'base_dashboard_screen.dart';
import 'models/unified_telemetry.dart';
import 'package:flutter/material.dart';

class WicDashboardScreen extends StatelessWidget {
  final String deviceId;

  const WicDashboardScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    return BaseDashboardScreen(
      deviceId: deviceId,
      title: "WALK-IN COOLER",
      buildPills: (UnifiedTelemetry t) => [
        Pill("COMPRESSOR 1", t.compressor1 ? "ON" : "OFF"),
        Pill("COMPRESSOR 2", t.compressor2 ? "ON" : "OFF"),
        Pill("DEFROST", t.defrost ? "ON" : "OFF"),
        Pill("PROBE", t.probeOk ? "OK" : "FAIL"),
        Pill("ALARM", t.alarm),
        Pill("BATTERY", "${t.battery}%"),
      ],
    );
  }
}
