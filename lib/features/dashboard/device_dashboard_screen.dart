// ignore_for_file: deprecated_member_use

import 'bbr_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/responsive.dart';
import '../devices/widgets/status_badge.dart';
import 'widgets/telemetry_tile.dart';
import 'widgets/temperature_chart.dart';
import 'deep_freezer_dashboard_screen.dart';
import 'widgets/dashboard_top_bar.dart';
import 'pai_dashboard_screen.dart';
import 'wic_dashboard_screen.dart';

class DeviceDashboardScreen extends StatelessWidget {
  final String deviceId;

  const DeviceDashboardScreen({super.key, required this.deviceId});

  // ✅ Dummy telemetry generator (for now)
  // Later: replace with API response from Azure Functions
  Map<String, dynamic> _mockTelemetry(String deviceId) {
    // Just some sample values based on deviceId (so each device looks different)
    final temp = deviceId.hashCode % 10 - 25; // range around -25
    return {
      "temperature": "$temp°C",
      "door": "CLOSED",
      "power": "ON",
      "health": "ONLINE",
      "status": "NORMAL",
      "lastUpdated": DateTime.now().toIso8601String(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final activeDeviceId = args?["deviceId"] ?? deviceId;
    final equipmentType = args?["equipmentType"] ?? "UNKNOWN";

    if (equipmentType == "DEEP_FREEZER") {
      return DeepFreezerDashboardScreen(deviceId: activeDeviceId);
    }

    if (equipmentType == "BBR") {
      return BbrDashboardScreen(deviceId: activeDeviceId);
    }

    if (equipmentType == "PLATELET") {
      return PaiDashboardScreen(deviceId: activeDeviceId);
    }

    if (equipmentType == "WALK_IN_COOLER") {
      return WicDashboardScreen(deviceId: activeDeviceId);
    }

    final telemetry = _mockTelemetry(activeDeviceId);

    final lastUpdated = DateTime.tryParse(telemetry["lastUpdated"] ?? "");
    final formattedLast = lastUpdated == null
        ? "-"
        : DateFormat("dd MMM, hh:mm a").format(lastUpdated);

    final padding = Responsive.pad(context);

    return Scaffold(
      appBar: const DashboardTopBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.12),
                      ),
                      child: Icon(
                        Icons.device_thermostat,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activeDeviceId,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontSize: 18),
                                ),
                              ),
                              StatusBadge(status: telemetry["status"] ?? "NORMAL")
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            equipmentType.replaceAll("_", " "),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Last updated: $formattedLast",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "Live Status",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // Telemetry grid (responsive)
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final crossAxisCount = w > 430 ? 2 : 2;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: [
                    TelemetryTile(
                      icon: Icons.thermostat,
                      title: "Temperature",
                      value: telemetry["temperature"] ?? "-",
                      subtitle: "Current reading",
                    ),
                    TelemetryTile(
                      icon: Icons.door_front_door_outlined,
                      title: "Door",
                      value: telemetry["door"] ?? "-",
                      subtitle: "Open/close status",
                    ),
                    TelemetryTile(
                      icon: Icons.power_settings_new,
                      title: "Power",
                      value: telemetry["power"] ?? "-",
                      subtitle: "Power supply state",
                    ),
                    TelemetryTile(
                      icon: Icons.wifi_tethering_outlined,
                      title: "Health",
                      value: telemetry["health"] ?? "-",
                      subtitle: "Connectivity status",
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),

            // Placeholder for graph + alerts (next step)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Temperature History",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              _RangeChip(label: "24h", isActive: true),
                              _RangeChip(label: "7d", isActive: false),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TemperatureChart(
                      points: const [-26, -25, -25, -24, -26, -27, -25, -24, -25, -26],
                    ),

                    const SizedBox(height: 8),
                    Text(
                      "Dummy chart now • will connect to Azure history API later",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _RangeChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
