// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/api/android_data_api.dart';
import '../notifications/notification_service.dart';
import 'widgets/status_row.dart';
import 'widgets/dashboard_top_bar.dart';
import 'widgets/last_sync_row.dart';
import '../notifications/alert_engine.dart';
import '../notifications/alert_settings.dart';
import '../notifications/alert_settings_storage.dart';

class PaiDashboardScreen extends StatefulWidget {
  final String deviceId;

  const PaiDashboardScreen({super.key, required this.deviceId});

  @override
  State<PaiDashboardScreen> createState() => _PaiDashboardScreenState();
}

class _PaiDashboardScreenState extends State<PaiDashboardScreen> {
  Timer? _timer;
  bool _loading = false;
  DateTime? _lastSync;
  final AlertEngine _alertEngine = AlertEngine();
  AlertSettings? _settings;

  Map<String, dynamic> _data = {};

  double? _double(String k) =>
      double.tryParse(_data[k]?.toString() ?? "");

  int _int(String k) =>
      int.tryParse(_data[k]?.toString() ?? "") ?? 0;

  // ======================
  // 🚨 SMART ALARM ENGINE
  // ======================

  String alarmText() {
    final battery = _int("battery");
    final pv = _double("pv");
    final sv = _double("sv");

    if (battery > 0 && battery < 20) {
      return "LOW BATTERY";
    }

    if (pv != null && sv != null && pv > sv + 1.5) {
      return "HIGH TEMP";
    }

    if (pv != null && sv != null && pv < sv - 1.5) {
      return "LOW TEMP";
    }

    return "NORMAL";
  }

  Color alarmColor() {
    switch (alarmText()) {
      case "HIGH TEMP":
        return Colors.redAccent;
      case "LOW TEMP":
        return Colors.lightBlueAccent;
      case "LOW BATTERY":
        return Colors.orangeAccent;
      default:
        return Colors.greenAccent;
    }
  }

  // ======================

  String tempValue(String k) {
    final v = _double(k);
    if (v == null) return "--";
    return "${v.toStringAsFixed(1)}°C";
  }

  String onOff(String k) => _int(k) == 1 ? "ON" : "OFF";

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() => _loading = true);

    final data = await AndroidDataApi.fetchByDeviceId(widget.deviceId);
    if (!mounted) return;

    if (data == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _data = Map<String, dynamic>.from(data);
      _loading = false;
      _lastSync = DateTime.now();
    });

    final pv = _double("pv");
    final sv = _double("sv");

    if (_settings != null && pv != null && sv != null) {
      final shouldAlert = _alertEngine.shouldTrigger(
        pv: pv,
        sv: sv,
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
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _fetch());
    _loadAlertSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pv = tempValue("pv");
    final sv = tempValue("sv");
    final power = onOff("power");
    final battery = _int("battery");

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: DashboardTopBar(
        deviceId: widget.deviceId,
        powerText: "Power: $power",
        batteryText: battery == 0 ? "--%" : "$battery%",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const SizedBox(height: 18),

            const Text(
              "PLATELET AGITATOR INCUBATOR",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF60A5FA),
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 14),

            const Text("PV",
                style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              pv,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Color(0xFF22C55E),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "SV  $sv",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF38BDF8),
              ),
            ),

            const SizedBox(height: 8),

            LastSyncRow(
              lastSync: _lastSync,
              loading: _loading,
            ),

            const SizedBox(height: 22),
            Divider(color: Colors.white.withOpacity(0.12)),
            const SizedBox(height: 10),

            StatusRow(
              icon: Icons.sync,
              label: "Agitator",
              value: onOff("agitator"),
              isGood: _int("agitator") == 1,
            ),

            StatusRow(
              icon: Icons.settings,
              label: "Compressor",
              value: onOff("compressor"),
              isGood: _int("compressor") == 1,
            ),

            StatusRow(
              icon: Icons.local_fire_department_outlined,
              label: "Heater",
              value: onOff("heater"),
              isGood: _int("heater") == 0,
            ),

            StatusRow(
              icon: Icons.thermostat,
              label: "Probe",
              value: _int("probe") == 1 ? "OK" : "FAIL",
              isGood: _int("probe") == 1,
            ),

            // 🚨 SMART ALARM ROW
            StatusRow(
              icon: Icons.notifications_active,
              label: "Alarm",
              value: alarmText(),
              valueColor: alarmColor(),
              isGood: alarmText() == "NORMAL",
            ),

            StatusRow(
              icon: Icons.battery_full,
              label: "Battery",
              value: battery == 0 ? "--%" : "$battery%",
              valueColor:
                  battery < 20 ? Colors.orangeAccent : Colors.greenAccent,
              isGood: battery >= 20,
            ),

            const SizedBox(height: 20),

            Text(
              "Device ID: ${widget.deviceId}",
              style: const TextStyle(color: Colors.white38),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
