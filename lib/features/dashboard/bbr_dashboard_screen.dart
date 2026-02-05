// ignore_for_file: unnecessary_type_check

import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/api/android_data_api.dart';
import '../../data/session/session_manager.dart';
import 'widgets/status_row.dart';
import 'widgets/dashboard_top_bar.dart';
import 'models/device_status.dart';
import 'utils/device_status_mapper.dart';
import '../notifications/alert_engine.dart';
import '../notifications/alert_settings.dart';
import '../notifications/alert_settings_storage.dart';
import '../notifications/notification_service.dart';

class BbrDashboardScreen extends StatefulWidget {
  final String deviceId;

  const BbrDashboardScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<BbrDashboardScreen> createState() => _BbrDashboardScreenState();
}

class _BbrDashboardScreenState extends State<BbrDashboardScreen> {
  Timer? _timer;
  DeviceStatus? _status;
  bool _loading = false;
  DateTime? _lastSync;
  final AlertEngine _alertEngine = AlertEngine();
  AlertSettings? _settings;


  bool isStale() {
    if (_lastSync == null) return true;
    return DateTime.now().difference(_lastSync!).inMinutes > 5;
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inSeconds < 10) return "a few seconds ago";
    if (diff.inSeconds < 60) return "${diff.inSeconds} sec ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    return "${diff.inDays} days ago";
  }

  Future<void> _fetch() async {
    if (_loading) return;

    setState(() => _loading = true);

    final telemetry =
        await AndroidDataApi.fetchByDeviceId(widget.deviceId);

    if (!mounted) return;

    final lastSync =
        await SessionManager.getLastSync(widget.deviceId);

    setState(() {
      _status = telemetry == null
          ? null
          : DeviceStatusMapper.fromApi(telemetry);
      _lastSync = lastSync;
      _loading = false;
    });

    if (_settings != null && _status?.pv != null && _status?.sv != null) {
      final shouldAlert = _alertEngine.shouldTrigger(
        pv: _status!.pv!,
        sv: _status!.sv!,
        settings: _settings!,
      );

      if (shouldAlert) {
        await NotificationService.send(
          "Cold Chain Alert",
          "Temperature is abnormal for extended time",
        );
      }
    }
  }



  // ======================
  // 🚨 SMART ALARM LOGIC
  // ======================

  String alarmText(DeviceStatus s) {
    if (s.batteryPercent < 20) {
      return "LOW BATTERY";
    }

    if (s.pv != null && s.sv != null && s.pv! > s.sv! + 2) {
      return "HIGH TEMP";
    }

    if (s.pv != null && s.sv != null && s.pv! < s.sv! - 2) {
      return "LOW TEMP";
    }

    if (s.alarmActive) {
      return "ACTIVE";
    }

    return "NORMAL";
  }

  Color alarmColor(DeviceStatus s) {
    switch (alarmText(s)) {
      case "HIGH TEMP":
        return Colors.redAccent;
      case "LOW TEMP":
        return Colors.lightBlueAccent;
      case "LOW BATTERY":
        return Colors.orangeAccent;
      case "ACTIVE":
        return Colors.redAccent;
      default:
        return Colors.greenAccent;
    }
  }

  Future<void> _loadAlertSettings() async {
    final data = await AlertSettingsStorage.load();

    setState(() {
      _settings = AlertSettings(
        app: data["app"],
        email: data["email"],
        sms: data["sms"],
        level: data["level"],
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAlertSettings();
    _fetch();
    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _fetch(),
    );
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
      if (s == null) return "--";
      if (!s.compressorOn) return "OFF";
      if (s.highAmp) return "ON   0.0A  HIGH (A)";
      if (s.lowAmp) return "ON   0.0A  LOW (A)";
      return "ON   0.0A";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: DashboardTopBar(
        deviceId: widget.deviceId,
        powerText:
            s == null ? "Power: --" : "Power: ${s.powerOn ? "ON" : "OFF"}",
        batteryText: s == null ? "0%" : "${s.batteryPercent}%",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const SizedBox(height: 18),

            const Text(
              "BLOOD BAG REFRIGERATOR",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFF60A5FA),
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
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

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_loading) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  const Text("Currently syncing..."),
                ] else ...[
                  const Icon(Icons.sync, size: 14, color: Colors.white54),
                  const SizedBox(width: 6),
                  Text(
                    _lastSync == null
                        ? "Last sync: Never"
                        : "Last sync: ${_timeAgo(_lastSync!)}",
                    style: TextStyle(
                      color:
                          isStale() ? Colors.orangeAccent : Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 22),
            Divider(color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 10),

            StatusRow(
              icon: Icons.memory,
              label: "System",
              value:
                  s == null ? "--" : (s.systemOk ? "HEALTHY" : "FAILURE"),
              isGood: s?.systemOk ?? true,
            ),

            StatusRow(
              icon: Icons.settings,
              label: "Compressor",
              value: compressorText(),
              isGood: s?.compressorOn ?? false,
            ),

            StatusRow(
              icon: Icons.power_settings_new,
              label: "Power",
              value: s?.powerOn == true ? "ON" : "OFF",
              isGood: s?.powerOn ?? false,
            ),

            StatusRow(
              icon: Icons.thermostat,
              label: "Probe",
              value: s?.probeOk == true ? "OK" : "FAIL",
              isGood: s?.probeOk ?? false,
            ),

            // 🚨 SMART ALARM
            StatusRow(
              icon: Icons.notifications_active,
              label: "Alarm",
              value: s == null ? "--" : alarmText(s),
              valueColor:
                  s == null ? Colors.white54 : alarmColor(s),
              isGood: s != null && alarmText(s) == "NORMAL",
            ),

            StatusRow(
              icon: Icons.door_front_door,
              label: "Door",
              value: s?.doorClosed == true ? "CLOSED" : "OPEN",
              isGood: s?.doorClosed ?? true,
            ),

            const SizedBox(height: 20),

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
