// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/api/android_data_api.dart';
import 'widgets/status_row.dart';
import 'widgets/dashboard_top_bar.dart';

class WicDashboardScreen extends StatefulWidget {
  final String deviceId;

  const WicDashboardScreen({super.key, required this.deviceId});

  @override
  State<WicDashboardScreen> createState() => _WicDashboardScreenState();
}

class _WicDashboardScreenState extends State<WicDashboardScreen> {
  Timer? _timer;
  bool _loading = false;

  Map<String, dynamic> _data = {};

  String _formatValue(String key, dynamic value) {
    if (value == null) return "--";
    final s = value.toString().trim();
    if (s.isEmpty) return "--";

    if (key.toLowerCase() == "pv" || key.toLowerCase() == "sv") {
      if (s.contains("°")) return s;
      return "$s°C";
    }

    if (key.toLowerCase() == "battery") {
      return s.contains("%") ? s : "$s%";
    }

    if (key.toLowerCase() == "timestamp") return s;

    if (s == "1") {
      if (key.toLowerCase() == "door") return "OPEN";
      return "ON";
    }
    if (s == "0") {
      if (key.toLowerCase() == "door") return "CLOSED";
      return "OFF";
    }

    return s;
  }

  String _prettyLabel(String key) {
    final k = key.toLowerCase();
    switch (k) {
      case "pv":
        return "PV";
      case "sv":
        return "SV";
      case "compressor1":
        return "Compressor 1";
      case "compressor2":
        return "Compressor 2";
      case "compressor":
        return "Compressor";
      case "defrost":
        return "Defrost";
      case "probe":
        return "Probe";
      case "door":
        return "Door";
      case "alarm":
        return "Alarm";
      case "battery":
        return "Battery";
      case "power":
        return "Power";
      case "timestamp":
        return "Timestamp";
      default:
        return key
            .replaceAll("_", " ")
            .replaceAllMapped(
              RegExp(r'([a-z])([A-Z])'),
              (m) => "${m[1]} ${m[2]}",
            )
            .toUpperCase();
    }
  }

  IconData _iconForKey(String key) {
    final k = key.toLowerCase();
    switch (k) {
      case "compressor1":
      case "compressor2":
      case "compressor":
        return Icons.settings;
      case "defrost":
        return Icons.ac_unit;
      case "probe":
        return Icons.thermostat;
      case "door":
        return Icons.door_front_door_outlined;
      case "alarm":
        return Icons.notifications_active_outlined;
      case "battery":
        return Icons.battery_full;
      case "power":
        return Icons.power_settings_new;
      case "pv":
      case "sv":
        return Icons.device_thermostat;
      case "timestamp":
        return Icons.schedule;
      default:
        return Icons.info_outline;
    }
  }

  bool _isGood(String key, String v) {
    final k = key.toLowerCase();

    if (k == "door") return v.toUpperCase() == "CLOSED";
    if (k == "alarm") return v.toUpperCase() != "ON";

    if (v.toUpperCase() == "ON") return true;
    if (v.toUpperCase() == "OFF") return false;

    return true;
  }

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() => _loading = true);

    final data = await AndroidDataApi.fetchLatest();

    if (!mounted) return;

    if (data == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _data = Map<String, dynamic>.from(data);
      _loading = false;
    });
  }

  List<Widget> _buildDynamicRows() {
    if (_data.isEmpty) {
      return const [
        StatusRow(
          icon: Icons.info_outline,
          label: "No data",
          value: "--",
          isGood: true,
        ),
      ];
    }

    final shown = <String>{};
    final rows = <Widget>[];

    _data.forEach((key, value) {
      final normalizedKey = key.toLowerCase().trim();
      if (shown.contains(normalizedKey)) return;
      shown.add(normalizedKey);

      if (normalizedKey == "pv" || normalizedKey == "sv") return;

      final formatted = _formatValue(key, value);

      rows.add(
        StatusRow(
          icon: _iconForKey(key),
          label: _prettyLabel(key),
          value: formatted,
          isGood: _isGood(key, formatted),
        ),
      );
    });

    return rows;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetch();
    });

    _timer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _fetch();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pv = _formatValue("pv", _data["pv"]);
    final sv = _formatValue("sv", _data["sv"]);
    final power = _formatValue("power", _data["power"]);
    final battery = _formatValue("battery", _data["battery"]);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: DashboardTopBar(
        powerText: "Power: $power",
        batteryText: battery,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          final maxContentWidth = w > 600 ? 520.0 : w;
          double titleSize = w < 360 ? 22 : (w < 450 ? 26 : 28);
          double pvSize = w < 360 ? 52 : (w < 450 ? 62 : 70);
          double svSize = w < 360 ? 28 : (w < 450 ? 32 : 36);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 18),

                    Text(
                      "WALK-IN COOLER",
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF60A5FA),
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    if (_loading)
                      Text(
                        "Fetching latest data...",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                    const SizedBox(height: 14),

                    if (_data.containsKey("pv")) ...[
                      const Text(
                        "PV",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          pv,
                          style: TextStyle(
                            fontSize: pvSize,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF22C55E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_data.containsKey("sv")) ...[
                      const Text(
                        "SV",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sv,
                        style: TextStyle(
                          fontSize: svSize,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Divider(color: Colors.white.withOpacity(0.12), height: 1),
                    const SizedBox(height: 10),

                    Column(
                      children: _buildDynamicRows(),
                    ),

                    const SizedBox(height: 26),
                    Text(
                      "Device ID: ${widget.deviceId}",
                      style: const TextStyle(color: Colors.white38),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
