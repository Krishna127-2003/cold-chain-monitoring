// ignore_for_file: unnecessary_type_check

import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/api/android_data_api.dart';
import 'widgets/status_row.dart';
import 'widgets/dashboard_top_bar.dart';
import 'models/device_status.dart';
import 'utils/device_status_mapper.dart';

class DeepFreezerDashboardScreen extends StatefulWidget {
  final String deviceId;
  const DeepFreezerDashboardScreen({super.key, required this.deviceId});

  @override
  State<DeepFreezerDashboardScreen> createState() =>
      _DeepFreezerDashboardScreenState();
}

class _DeepFreezerDashboardScreenState
    extends State<DeepFreezerDashboardScreen> {
  Timer? _timer;
  DeviceStatus? _status;
  bool _loading = false;

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() => _loading = true);

    final raw = await AndroidDataApi.fetchLatest();
    if (!mounted) return;

    Map<String, dynamic>? deviceData;
    if (raw != null) {
      // CASE 1: API returns map keyed by deviceId
      if (raw[widget.deviceId] is Map) {
        deviceData = Map<String, dynamic>.from(raw[widget.deviceId]);
      }
      // CASE 2: API returns list of devices
      else if (raw["devices"] is List) {
        for (final item in raw["devices"]) {
          if (item is Map) {
            final id = (item["deviceId"] ?? item["id"] ?? "").toString();
            if (id == widget.deviceId) {
              deviceData = Map<String, dynamic>.from(item);
              break;
            }
          }
        }
      }
      // CASE 3: API returns direct device data (fallback)
      else if (raw is Map && raw.containsKey("mixbit12")) {
        deviceData = raw;
      }
    }

    setState(() {
      _status = deviceData == null ? null : DeviceStatusMapper.fromApi(deviceData);
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;

    String compressorText() {
      if (s == null || !s.compressorOn) return "OFF";
      if (s.lowAmp) return "ON   0.0A  LOW AMP";
      if (s.highAmp) return "ON   0.0A  HIGH AMP";
      return "ON   0.0A";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: DashboardTopBar(
        powerText: s == null
            ? "Power: --"
            : "Power: ${s.powerOn ? "ON" : "OFF"}",
        batteryText: s == null
            ? "0%"
            : "${s.batteryPercent}%",
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const SizedBox(height: 18),

            const Text(
              "DEEP FREEZER",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFF60A5FA),
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 20),

            if (s?.pv != null) ...[
              const Text("PV",
                  style: TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 6),
              Text(
                "${s!.pv!.toStringAsFixed(1)}°C",
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF22C55E),
                ),
              ),
            ],

            const SizedBox(height: 10),

            if (s?.sv != null)
              Text(
                "SV  ${s!.sv!.toStringAsFixed(1)}°C",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF38BDF8),
                ),
              ),

            const SizedBox(height: 22),
            Divider(color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 10),

            /// 1️⃣ SYSTEM
            StatusRow(
              icon: Icons.memory,
              label: "System",
              value: s == null
                  ? "--"
                  : (s.systemOk ? "HEALTHY" : "FAILURE"),
              isGood: s?.systemOk ?? true,
            ),

            /// 2️⃣ COMPRESSOR
            StatusRow(
              icon: Icons.settings,
              label: "Compressor",
              value: compressorText(),
              isGood: s?.compressorOn ?? false,
            ),

            /// 3️⃣ POWER
            StatusRow(
              icon: Icons.power_settings_new,
              label: "Power",
              value: s?.powerOn == true ? "ON" : "OFF",
              isGood: s?.powerOn ?? false,
            ),

            /// 4️⃣ PROBE
            StatusRow(
              icon: Icons.thermostat,
              label: "Probe",
              value: s?.probeOk == true ? "OK" : "FAIL",
              isGood: s?.probeOk ?? false,
            ),

            /// 5️⃣ ALARM
            StatusRow(
              icon: Icons.notifications_active,
              label: "Alarm",
              value: s == null
                  ? "--"
                  : s.alarmActive
                      ? (s.alarmMuted ? "MUTE" : "ACTIVE")
                      : "OFF",
              isGood: !(s?.alarmActive ?? false),
            ),

            /// 6️⃣ DOOR
            StatusRow(
              icon: Icons.door_front_door,
              label: "Door",
              value: s?.doorClosed == true ? "CLOSED" : "OPEN",
              isGood: s?.doorClosed ?? true,
            ),

            /// 7️⃣ UPDATED
            StatusRow(
              icon: Icons.schedule,
              label: "Updated",
              value: s?.updatedAt?.toIso8601String() ?? "--",
              isGood: true,
            ),

            const SizedBox(height: 20),

            /// 8️⃣ DEVICE ID
            Text(
              "Device ID: ${widget.deviceId}",
              style: const TextStyle(color: Colors.white38),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
