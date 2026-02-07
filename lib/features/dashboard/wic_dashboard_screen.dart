// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/api/android_data_api.dart';
import '../notifications/notification_service.dart';
import 'widgets/dashboard_top_bar.dart';

import '../notifications/alert_engine.dart';
import '../notifications/alert_settings.dart';
import '../notifications/alert_settings_storage.dart';

import 'models/unified_telemetry.dart';

class WicDashboardScreen extends StatefulWidget {
  final String deviceId;

  const WicDashboardScreen({super.key, required this.deviceId});

  @override
  State<WicDashboardScreen> createState() => _WicDashboardScreenState();
}

class _WicDashboardScreenState extends State<WicDashboardScreen> {
  Timer? _timer;

  UnifiedTelemetry? _telemetry;
  DateTime? _lastSync;
  bool _loading = false;

  final AlertEngine _alertEngine = AlertEngine();
  AlertSettings? _settings;

  // ================= FETCH =================

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() => _loading = true);

    final telemetry =
        await AndroidDataApi.fetchByDeviceId(widget.deviceId);
    if (!mounted) return;

    setState(() {
      _telemetry = telemetry;
      _lastSync = DateTime.now();
      _loading = false;
    });

    if (_settings != null &&
        telemetry?.pv != null &&
        telemetry?.sv != null) {
      final shouldAlert = _alertEngine.shouldTrigger(
        pv: telemetry!.pv!,
        sv: telemetry.sv!,
        settings: _settings!,
      );

      if (shouldAlert) {
        await NotificationService.send(
          "Cold Chain Alert",
          "Temperature abnormal for extended time",
        );
      }
    }
  }


  Future<void> _loadAlertSettings() async {
    final d = await AlertSettingsStorage.load();
    _settings = AlertSettings(
      app: d["app"],
      email: d["email"],
      sms: d["sms"],
      level: d["level"],
    );
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

  // ================= UI HELPERS =================

  bool isStale() =>
      _lastSync == null ||
      DateTime.now().difference(_lastSync!).inMinutes > 5;

  String timeAgo() {
    if (_lastSync == null) return "Never";
    final d = DateTime.now().difference(_lastSync!);
    if (d.inSeconds < 60) return "a few seconds ago";
    if (d.inMinutes < 60) return "${d.inMinutes} min ago";
    return "${d.inHours} hrs ago";
  }

  Widget glassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget pillRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              )),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final t = _telemetry;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: DashboardTopBar(
        deviceId: widget.deviceId,
        powerText:
            t == null ? "Power: --" : "Power: ${t.powerOn ? "ON" : "OFF"}",
        batteryText:
            t == null ? "--%" : "${t.battery}%",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            glassCard(
              Column(
                children: [
                  const Text(
                    "WALK-IN COOLER",
                    style: TextStyle(
                      letterSpacing: 2,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    t?.pv == null
                        ? "--.- °C"
                        : "${t!.pv!.toStringAsFixed(1)} °C",
                    style: const TextStyle(
                      fontSize: 66,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.08),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      t?.sv == null
                          ? "SET --.- °C"
                          : "SET ${t!.sv!.toStringAsFixed(1)} °C",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sync,
                          size: 14, color: Colors.white54),
                      const SizedBox(width: 6),
                      Text(
                        "Last sync: ${timeAgo()}",
                        style: TextStyle(
                          color: isStale()
                              ? Colors.orangeAccent
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "DEVICE ID : ${widget.deviceId}",
                    style: const TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            glassCard(
              Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "DEVICE DETAILS",
                      style: TextStyle(
                        color: Colors.white60,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  pillRow("COMPRESSOR 1", t?.compressor1 == true ? "ON" : "OFF"),
                  pillRow("COMPRESSOR 2", t?.compressor2 == true ? "ON" : "OFF"),
                  pillRow("DEFROST", t?.defrost == true ? "ON" : "OFF"),
                  pillRow("PROBE", t?.probeOk == true ? "OK" : "FAIL"),
                  pillRow("ALARM", t?.alarm ?? "NORMAL"),
                  pillRow("BATTERY", t == null ? "--%" : "${t.battery}%"),
                ],
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
