import 'base_dashboard_screen.dart';
import 'models/unified_telemetry.dart';
import 'package:flutter/material.dart';

class CoolpodDashboardScreen extends StatelessWidget {
  final String deviceId;

  const CoolpodDashboardScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    return BaseDashboardScreen(
      deviceId: deviceId,
      title: "ACTIVE COOLPOD",
      buildPills: (UnifiedTelemetry t) => [
        Pill("POWER", t.powerOn ? "ON" : "OFF"),
        Pill("BATTERY", "${t.battery}%"),
        Pill("COMPRESSOR", t.compressor ? "ON" : "OFF"),
        Pill("TEMPERATURE", "${t.pv} °C"),
        Pill("SET TEMP", "${t.sv} °C"),
        Pill("ALARM", t.alarm),
        Pill("PROBE", t.probeOk ? "OK" : "FAIL"),
      ],
    );
  }
}