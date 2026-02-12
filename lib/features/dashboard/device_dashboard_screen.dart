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
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final activeDeviceId = args?["deviceId"] ?? deviceId;
    final equipmentType = args?["equipmentType"] ?? this.equipmentType;

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
