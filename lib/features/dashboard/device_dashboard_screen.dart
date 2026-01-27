// ignore_for_file: deprecated_member_use, no_leading_underscores_for_local_identifiers

import 'dart:async';

import 'bbr_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/responsive.dart';
import '../../data/api/android_data_api.dart';
import '../devices/widgets/status_badge.dart';
import 'widgets/telemetry_tile.dart';
import 'widgets/temperature_chart.dart';
import 'deep_freezer_dashboard_screen.dart';
import 'widgets/dashboard_top_bar.dart';
import 'pai_dashboard_screen.dart';
import 'wic_dashboard_screen.dart';

class DeviceDashboardScreen extends StatefulWidget {
  final String deviceId;

  const DeviceDashboardScreen({super.key, required this.deviceId});

  @override
  State<DeviceDashboardScreen> createState() => _DeviceDashboardScreenState();
}

class _DeviceDashboardScreenState extends State<DeviceDashboardScreen> {
  Timer? _alignedTimer;
  bool _loading = false;

  /// ✅ Latest telemetry (from GetAndroidData)
  Map<String, dynamic> _telemetry = {
    "temperature": "-",
    "door": "-",
    "power": "-",
    "health": "-",
    "status": "NORMAL",
    "lastUpdated": "",
  };

  String _fmtTemp(dynamic pv) {
    if (pv == null) return "-";

    final s = pv.toString().trim();
    if (s.isEmpty) return "-";

    // if already contains °C, return
    if (s.contains("°")) return s;

    return "$s°C";
  }

  String _doorText(dynamic door) {
    final v = door.toString().trim();
    if (v == "1") return "OPEN";
    if (v == "0") return "CLOSED";
    return "-";
  }

  String _powerText(dynamic power) {
    final v = power.toString().trim();
    if (v == "1") return "ON";
    if (v == "0") return "OFF";
    return "-";
  }

  String _statusFromFlags(Map<String, dynamic> data) {
    final lowamp = (data["lowamp"] ?? "").toString().trim();
    final highamp = (data["highamp"] ?? "").toString().trim();

    // ✅ If any alarm flag triggers, show ALARM
    if (lowamp == "1" || highamp == "1") return "ALARM";

    return "NORMAL";
  }

  Future<void> _fetchLive() async {
    if (_loading) return;

    setState(() => _loading = true);

    final data = await AndroidDataApi.fetchLatest();

    if (!mounted) return;

    if (data != null) {
      final t = {
        "temperature": _fmtTemp(data["pv"]),
        "door": _doorText(data["door"]),
        "power": _powerText(data["power"]),
        "health": "ONLINE",
        "status": _statusFromFlags(data),
        "lastUpdated": (data["timestamp"] ?? "").toString(),
      };

      setState(() {
        _telemetry = t;
        _loading = false;
      });
    } else {
      setState(() {
        _telemetry = {
          ..._telemetry,
          "health": "OFFLINE",
        };
        _loading = false;
      });
    }
  }

  /// ✅ Vinay schedule: 4,9,14,19,...59 minute every hour
  void _startAlignedSchedule() {
    _alignedTimer?.cancel();

    final alignedMinutes = <int>[4, 9, 14, 19, 24, 29, 34, 39, 44, 49, 54, 59];

    DateTime _nextAlignedTime(DateTime now) {
      final currentMinute = now.minute;
      final currentSecond = now.second;

      int nextMinute = -1;
      for (final m in alignedMinutes) {
        if (m > currentMinute || (m == currentMinute && currentSecond < 2)) {
          nextMinute = m;
          break;
        }
      }

      if (nextMinute == -1) {
        // ✅ Next hour at minute 4
        return DateTime(now.year, now.month, now.day, now.hour + 1, 4, 0);
      }

      return DateTime(now.year, now.month, now.day, now.hour, nextMinute, 0);
    }

    void _scheduleNextTick() {
      if (!mounted) return;

      final now = DateTime.now();
      final nextTime = _nextAlignedTime(now);
      final delay = nextTime.difference(now);

      _alignedTimer?.cancel();
      _alignedTimer = Timer(delay, () async {
        if (!mounted) return;

        await _fetchLive();

        // ✅ after executing once, schedule next aligned again
        _scheduleNextTick();
      });
    }

    _scheduleNextTick();
  }

  @override
  void initState() {
    super.initState();

    // ✅ immediate first fetch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchLive();
      _startAlignedSchedule();
    });
  }

  @override
  void dispose() {
    _alignedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final activeDeviceId = args?["deviceId"] ?? widget.deviceId;
    final equipmentType = args?["equipmentType"] ?? "UNKNOWN";

    // ✅ If equipment dashboards already exist, keep them untouched
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

    final lastUpdated =
        DateTime.tryParse((_telemetry["lastUpdated"] ?? "").toString());
    final formattedLast = lastUpdated == null
        ? "-"
        : DateFormat("dd MMM, hh:mm a").format(lastUpdated.toLocal());

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
                              StatusBadge(
                                  status: _telemetry["status"] ?? "NORMAL")
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
                          const SizedBox(height: 6),
                          if (_loading)
                            Text(
                              "Fetching latest data...",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w700,
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
                      value: (_telemetry["temperature"] ?? "-").toString(),
                      subtitle: "Current reading (PV)",
                    ),
                    TelemetryTile(
                      icon: Icons.door_front_door_outlined,
                      title: "Door",
                      value: (_telemetry["door"] ?? "-").toString(),
                      subtitle: "Open/close status",
                    ),
                    TelemetryTile(
                      icon: Icons.power_settings_new,
                      title: "Power",
                      value: (_telemetry["power"] ?? "-").toString(),
                      subtitle: "Power supply state",
                    ),
                    TelemetryTile(
                      icon: Icons.wifi_tethering_outlined,
                      title: "Health",
                      value: (_telemetry["health"] ?? "-").toString(),
                      subtitle: "API connectivity",
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
