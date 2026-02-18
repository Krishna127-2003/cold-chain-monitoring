import 'package:flutter/material.dart';

import 'deep_freezer_dashboard_screen.dart';
import 'bbr_dashboard_screen.dart';
import 'pai_dashboard_screen.dart';
import 'wic_dashboard_screen.dart';

class DeviceDashboardScreen extends StatelessWidget {
  final String deviceId;
  final String equipmentType;

  const DeviceDashboardScreen({super.key, required this.deviceId, required this.equipmentType});

  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args =
        rawArgs is Map<String, dynamic> ? rawArgs : const <String, dynamic>{};

    final activeDeviceId = (args["deviceId"] ?? deviceId).toString();
    final equipmentType =
        (args["equipmentType"] ?? this.equipmentType).toString();

    switch (equipmentType) {
      case "DEEP_FREEZER":
        return DeepFreezerDashboardScreen(deviceId: activeDeviceId);

      case "BBR":
        return BbrDashboardScreen(deviceId: activeDeviceId);

      case "PLATELET":
        return PaiDashboardScreen(deviceId: activeDeviceId);

      case "WALK_IN_COOLER":
        return WicDashboardScreen(deviceId: activeDeviceId);

      default:
        return Scaffold(
          backgroundColor: const Color(0xFF0A1020),
          body: Center(
            child: Text(
              "Unsupported device type",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          ),
        );
    }
  }
}
