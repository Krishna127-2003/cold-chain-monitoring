// ignore_for_file: deprecated_member_use, no_leading_underscores_for_local_identifiers, unused_field

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/responsive.dart';
import '../../data/api/android_data_api.dart';
import '../devices/widgets/status_badge.dart';
import 'widgets/telemetry_tile.dart';
import 'widgets/temperature_chart.dart';
import 'widgets/dashboard_top_bar.dart';

import 'utils/telemetry_mapper.dart';

import 'deep_freezer_dashboard_screen.dart';
import 'bbr_dashboard_screen.dart';
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

  Map<String, dynamic> _rawTelemetry = {};
  String _health = "OFFLINE";
  String _status = "NORMAL";
  String _lastUpdated = "";

  Future<void> _fetchLive() async {
    if (_loading) return;
    setState(() => _loading = true);

    final data = await AndroidDataApi.fetchLatest();

    if (!mounted) return;

    if (data != null && data.isNotEmpty) {
      setState(() {
        _rawTelemetry = Map<String, dynamic>.from(data);
        _health = "ONLINE";
        _status = _deriveStatus(data);
        _lastUpdated = (data["timestamp"] ?? "").toString();
        _loading = false;
      });
    } else {
      setState(() {
        _health = "OFFLINE";
        _loading = false;
      });
    }
  }

  String _deriveStatus(Map<String, dynamic> data) {
    final lowamp = (data["lowamp"] ?? "").toString();
    final highamp = (data["highamp"] ?? "").toString();
    return (lowamp == "1" || highamp == "1") ? "ALARM" : "NORMAL";
  }

  void _startAlignedSchedule() {
    _alignedTimer?.cancel();

    final alignedMinutes = [4, 9, 14, 19, 24, 29, 34, 39, 44, 49, 54, 59];

    DateTime nextRun(DateTime now) {
      for (final m in alignedMinutes) {
        if (m > now.minute) {
          return DateTime(now.year, now.month, now.day, now.hour, m);
        }
      }
      return DateTime(now.year, now.month, now.day, now.hour + 1, 4);
    }

    void schedule() {
      final now = DateTime.now();
      final delay = nextRun(now).difference(now);

      _alignedTimer = Timer(delay, () async {
        await _fetchLive();
        schedule();
      });
    }

    schedule();
  }

  @override
  void initState() {
    super.initState();
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

    // Keep existing dashboards untouched
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

    final lastUpdatedDate =
        DateTime.tryParse(_lastUpdated.isEmpty ? "" : _lastUpdated);
    final formattedLast = lastUpdatedDate == null
        ? "-"
        : DateFormat("dd MMM, hh:mm a").format(lastUpdatedDate.toLocal());

    final padding = Responsive.pad(context);

    // 🔥 DYNAMIC TELEMETRY (unique keys only)
    final telemetryEntries = _rawTelemetry.entries.toList();

    return Scaffold(
      appBar: const DashboardTopBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.device_thermostat),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(activeDeviceId,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(equipmentType.replaceAll("_", " ")),
                          const SizedBox(height: 4),
                          Text("Last updated: $formattedLast",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall),
                        ],
                      ),
                    ),
                    StatusBadge(status: _status),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text("Live Status",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: .80,
              ),
              itemCount: telemetryEntries.length,
              itemBuilder: (context, index) {
                final entry = telemetryEntries[index];
                final key = entry.key;
                final rawValue = entry.value;

                final value =
                    TelemetryMapper.formatValue(key, rawValue);
                final isGood =
                    TelemetryMapper.isGood(key, value);

                return TelemetryTile(
                  icon: Icons.info_outline,
                  title: TelemetryMapper.prettifyKey(key),
                  value: value,
                  subtitle: isGood ? "Normal" : "Attention",
                );
              },
            ),

            const SizedBox(height: 18),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Temperature History"),
                    SizedBox(height: 12),
                    TemperatureChart(
                      points: [-26, -25, -24, -26, -27, -25],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "History API will be connected later",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
