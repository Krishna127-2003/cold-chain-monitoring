// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/api/android_data_api.dart';
import 'widgets/status_row.dart';
import 'widgets/dashboard_top_bar.dart';

class DeepFreezerDashboardScreen extends StatefulWidget {
  final String deviceId;

  const DeepFreezerDashboardScreen({super.key, required this.deviceId});

  @override
  State<DeepFreezerDashboardScreen> createState() =>
      _DeepFreezerDashboardScreenState();
}

class _DeepFreezerDashboardScreenState extends State<DeepFreezerDashboardScreen> {
  Timer? _timer;
  bool _loading = false;

  /// ✅ Complete raw telemetry from API
  Map<String, dynamic> _data = {};

  /// ✅ Convert raw value into readable string (generic)
  String _formatValue(String key, dynamic value) {
    if (value == null) return "--";

    final s = value.toString().trim();
    if (s.isEmpty) return "--";

    // ✅ temp formatting
    if (key.toLowerCase() == "pv" || key.toLowerCase() == "sv") {
      if (s.contains("°")) return s;
      return "$s°C";
    }

    // ✅ timestamp formatting (keep as is for now)
    if (key.toLowerCase() == "timestamp") return s;

    // ✅ binary flag formatting
    if (s == "1") {
      if (key.toLowerCase() == "door") return "OPEN";
      return "ON";
    }
    if (s == "0") {
      if (key.toLowerCase() == "door") return "CLOSED";
      return "OFF";
    }

    // ✅ battery %
    if (key.toLowerCase() == "battery") {
      return s.contains("%") ? s : "$s%";
    }

    return s;
  }

  /// ✅ Better labels instead of raw key names
  String _prettyLabel(String key) {
    final k = key.toLowerCase();

    switch (k) {
      case "pv":
        return "PV";
      case "sv":
        return "SV";
      case "compressor":
        return "Compressor";
      case "defrost":
        return "Defrost Auto";
      case "probe":
        return "Probe";
      case "door":
        return "Door";
      case "battery":
        return "Battery";
      case "power":
        return "Power";
      case "lowamp":
        return "Low Amp Alarm";
      case "highamp":
        return "High Amp Alarm";
      case "timestamp":
        return "Timestamp";
      default:
        // Convert snake/camel to readable
        return key
            .replaceAll("_", " ")
            .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => "${m[1]} ${m[2]}")
            .toUpperCase();
    }
  }

  /// ✅ Icon mapping for known keys
  IconData _iconForKey(String key) {
    final k = key.toLowerCase();
    switch (k) {
      case "compressor":
        return Icons.settings;
      case "defrost":
        return Icons.ac_unit;
      case "probe":
        return Icons.thermostat;
      case "door":
        return Icons.door_front_door_outlined;
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

  /// ✅ Determine good/bad indicator automatically
  bool _isGood(String key, String v) {
    final k = key.toLowerCase();

    if (k == "door") return v.toUpperCase() == "CLOSED";
    if (k == "probe") return v.toUpperCase() == "ON" || v.toUpperCase() == "OK";

    // alarms: lowamp/highamp 1 means alarm, so bad
    if (k == "lowamp" || k == "highamp") return v != "ON";

    // general ON/OFF values: ON is usually good
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

  /// ✅ build list of rows dynamically (no duplicates)
  List<Widget> _buildDynamicRows() {
    if (_data.isEmpty) {
      return [
        const StatusRow(
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

      // ✅ Skip PV/SV because shown in big section (if present)
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
  Widget build(BuildContext context) {
    final pv = _formatValue("pv", _data["pv"]);
    final sv = _formatValue("sv", _data["sv"]);
    final power = _formatValue("power", _data["power"]);
    final battery = _formatValue("battery", _data["battery"]);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),

      /// ✅ TOP BAR shows power + battery dynamically
      appBar: DashboardTopBar(
        powerText: "Power: $power",
        batteryText: battery,
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          final maxContentWidth = w > 600 ? 520.0 : w;

          double titleSize = w < 360 ? 30 : (w < 450 ? 38 : 44);
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
                      "DEEP FREEZER",
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF60A5FA),
                        letterSpacing: 2,
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

                    /// ✅ Show PV only if API has it
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

                    /// ✅ Show SV only if API has it
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

                    /// ✅ Auto-generated rows (whatever URL returns)
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
