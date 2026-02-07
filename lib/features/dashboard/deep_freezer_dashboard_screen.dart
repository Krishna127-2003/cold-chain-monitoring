// ignore_for_file: unnecessary_type_check
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/api/android_data_api.dart';
import '../../data/session/session_manager.dart';
import '../notifications/notification_service.dart';
import 'widgets/dashboard_top_bar.dart';
import 'models/device_status.dart';
import 'utils/device_status_mapper.dart';
import '../notifications/alert_engine.dart';
import '../notifications/alert_settings.dart';
import '../notifications/alert_settings_storage.dart';

class DeepFreezerDashboardScreen extends StatefulWidget {
  final String deviceId;

  const DeepFreezerDashboardScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<DeepFreezerDashboardScreen> createState() =>
      _DeepFreezerDashboardScreenState();
}

class _DeepFreezerDashboardScreenState
    extends State<DeepFreezerDashboardScreen> {
  Timer? _timer;
  DeviceStatus? _status;
  DateTime? _lastSync;
  bool _loading = false;

  final AlertEngine _alertEngine = AlertEngine();
  AlertSettings? _settings;

  // ================= TIME =================

  bool isStale() =>
      _lastSync == null || DateTime.now().difference(_lastSync!).inMinutes > 5;

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 10) return "a few seconds ago";
    if (d.inSeconds < 60) return "${d.inSeconds} sec ago";
    if (d.inMinutes < 60) return "${d.inMinutes} min ago";
    if (d.inHours < 24) return "${d.inHours} hrs ago";
    return "${d.inDays} days ago";
  }

  // ================= FETCH =================

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
      final fire = _alertEngine.shouldTrigger(
        pv: _status!.pv!,
        sv: _status!.sv!,
        settings: _settings!,
      );

      if (fire) {
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
    _loadAlertSettings();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ================= GLASS HELPERS =================

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

  // ================= ALARM =================

  String alarmText(DeviceStatus s) {
    if (s.batteryPercent < 20) return "LOW BATTERY";
    if (s.pv! > s.sv! + 2) return "HIGH TEMP";
    if (s.pv! < s.sv! - 2) return "LOW TEMP";
    if (s.alarmActive) return "ACTIVE";
    return "OFF";
  }

  Color alarmColor(DeviceStatus s) {
    switch (alarmText(s)) {
      case "HIGH TEMP":
      case "ACTIVE":
        return Colors.redAccent;
      case "LOW BATTERY":
        return Colors.orangeAccent;
      case "LOW TEMP":
        return Colors.lightBlueAccent;
      default:
        return Colors.greenAccent;
    }
  }

  String compressorText() {
    final s = _status;
    if (s == null) return "--";
    if (!s.compressorOn) return "OFF";
    if (s.highAmp) return "ON  HIGH A";
    if (s.lowAmp) return "ON  LOW A";
    return "ON";
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final s = _status;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: DashboardTopBar(
        deviceId: widget.deviceId,
        powerText:
            s == null ? "Power: --" : "Power: ${s.powerOn ? "ON" : "OFF"}",
        batteryText: s == null ? "0%" : "${s.batteryPercent}%",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            glassCard(
              Column(
                children: [
                  const Text(
                    "DEEP FREEZER -40°C",
                    style: TextStyle(
                      letterSpacing: 2,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      s?.pv == null
                          ? "--.- °C"
                          : "${s!.pv!.toStringAsFixed(1)} °C",
                      key: ValueKey(s?.pv),
                      style: const TextStyle(
                        fontSize: 66,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
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
                      s?.sv == null
                          ? "SET --.- °C"
                          : "SET ${s!.sv!.toStringAsFixed(1)} °C",
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
                        _lastSync == null
                            ? "Last sync: Never"
                            : "Last sync: ${_timeAgo(_lastSync!)}",
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

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        "SYSTEM ",
                        style: TextStyle(
                          color: Colors.white60,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        s == null
                            ? "--"
                            : (s.systemOk ? "HEALTHY" : "ERROR"),
                        style: TextStyle(
                          color: s == null
                              ? Colors.white54
                              : (s.systemOk ? Colors.greenAccent : Colors.redAccent),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),


                  pillRow("POWER", s == null ? "--" : (s.powerOn ? "ON" : "OFF")),
                  pillRow("BATTERY", s == null ? "--" : "${s.batteryPercent} %"),
                  pillRow("COMPRESSOR", s == null ? "--" : compressorText()),
                  pillRow("ALARMS", s == null ? "--" : alarmText(s)),
                  pillRow("DOOR", s == null ? "--" : (s.doorClosed ? "CLOSED" : "OPEN")),
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
