import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/api/android_data_api.dart';
import '../../data/api/immediate_send_api.dart';
import 'storage/sensor_name_storage.dart';
import 'datalogger/models/datalogger_telemetry.dart';
import 'widgets/dashboard_top_bar.dart';
import '../dashboard/storage/telemetry_store.dart';
import '../dashboard/models/unified_telemetry.dart';

class DataLoggerDashboardScreen extends StatefulWidget {
  final String deviceId;

  const DataLoggerDashboardScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<DataLoggerDashboardScreen> createState() =>
      _DataLoggerDashboardScreenState();
}

class _DataLoggerDashboardScreenState
    extends State<DataLoggerDashboardScreen>
    with SingleTickerProviderStateMixin {

  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  DataloggerTelemetry? _telemetry;

  bool _initialLoading = true;
  bool _refreshing = false;
  bool _noInternet = false;
  
 UnifiedTelemetry? get _storeTelemetry =>
    TelemetryStore.get(widget.deviceId);
  DateTime? _lastManualRefresh;
  late AnimationController _refreshController;

  static const int _offlineThresholdMinutes = 16;

  final List<String> _names =
      List.generate(16, (i) => "Temp Sensor ${i + 1}");

  // ===================== TIME =====================


  bool get isOnline {
    final t = _storeTelemetry;
    if (t?.timestamp == null) return false;
    return DateTime.now()
            .difference(t!.timestamp!)
            .inMinutes <=
        _offlineThresholdMinutes;
  }

  bool get isStale {
    final t = _storeTelemetry;
    if (t?.timestamp == null) return true;
    return DateTime.now()
            .difference(t!.timestamp!)
            .inMinutes >
        _offlineThresholdMinutes;
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);

    if (d.inSeconds < 50) return "a few seconds ago";
    if (d.inSeconds < 60) return "1 min ago";
    if (d.inMinutes < 60) return "${d.inMinutes} min ago";
    if (d.inHours < 24) return "${d.inHours} hrs ago";
    return "${d.inDays} days ago";
  }

  // ===================== FETCH =====================

  Future<void> _fetch({bool isRefresh = false}) async {
    if (_refreshing) return;

    if (isRefresh) {
      _refreshing = true;
    } else if (_telemetry == null) {
      _initialLoading = true;
    }

    if (mounted) setState(() {});

    try {
      final data = await AndroidDataApi
          .fetchDatalogger(widget.deviceId)
          .timeout(const Duration(seconds: 6));

      if (!mounted) return;

      if (data != null) {
        _telemetry = data;

        TelemetryStore.set(
          widget.deviceId,
          UnifiedTelemetry.fromLogger(widget.deviceId, data),
        );
      }

      _noInternet = false;
    } catch (_) {
      _noInternet = true;
    }

    _initialLoading = false;
    _refreshing = false;

    if (mounted) setState(() {});
  }

  void _showDiagnoseImage() {
    final temps = _telemetry?.temps ?? List.filled(16, null);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,  // full width dialog
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InteractiveViewer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Stack(
                  children: [
                    Image.asset(
                      "assets/images/diagnose.png",
                      fit: BoxFit.contain,
                      width: w,
                    ),
                    ..._buildTempPoints(temps, w, h),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _listenConnectivity() {
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) {
      final hasInternet =
          !results.contains(ConnectivityResult.none);

      if (hasInternet && _noInternet) {
        if (!mounted) return;

        setState(() => _noInternet = false);
        _fetch();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connected — refreshing data"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _manualRefresh() async {
    _refreshController.repeat();

    final now = DateTime.now();

    if (_lastManualRefresh == null ||
        now.difference(_lastManualRefresh!).inSeconds >= 20) {
      _lastManualRefresh = now;
      await _fetch(isRefresh: true);
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
    }

    _refreshController.stop();
    _refreshController.reset();
  }

  // ===================== SENSOR NAMES =====================

  Future<void> _loadNames() async {
    for (int i = 0; i < 16; i++) {
      _names[i] =
          await SensorNameStorage.getName(widget.deviceId, i + 1);
    }
    if (mounted) setState(() {});
  }

  Future<void> _renameSensor(int index) async {
    final controller =
        TextEditingController(text: _names[index]);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename Sensor"),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    await SensorNameStorage.setName(
        widget.deviceId, index + 1, result);

    setState(() => _names[index] = result);
  }

  // ===================== INIT =====================

  @override
  void initState() {
    super.initState();

    _loadNames();

    ImmediateSendApi.trigger(widget.deviceId);

    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fetch();
    _listenConnectivity();

    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) async {
        try {
          await ImmediateSendApi.trigger(widget.deviceId);
          await _fetch(isRefresh: true);
        } catch (_) {}
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySub?.cancel();
    _refreshController.dispose();
    super.dispose();
  }

  // ===================== UI =====================

  Widget glassPill(String label, String value, VoidCallback onLongPress) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _point(double? value, Color color,
      {double? top, double? left, double? right, double? bottom}) {
    return Positioned(
      top: top, left: left, right: right, bottom: bottom,
      child: Text(
        value == null ? "--°C" : "${value.toStringAsFixed(1)}°C",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
        ),
      ),
    );
  }

  List<Widget> _buildTempPoints(List<double?> t, double w, double h) {
    const hp  = Color(0xFFFF6600);   // orange — high pressure gas
    const hpl = Color(0xFFFFCC00);   // yellow — high pressure liquid
    const lp  = Color(0xFF44AAFF);   // blue   — low pressure gas
    const lpl = Color(0xFF44DD88);   // green  — low pressure liquid

    return [
      _point(t[0],  lp,  top: h * 0.035, left: w * 0.295),        // ① compressor inlet (blue)
      _point(t[1],  hp,  top: h * 0.035, left: w * 0.4),        // ② compressor outlet
      _point(t[2],  hp,  top: h * 0.035, left: w * 0.63),        // ③ discharge line
      _point(t[3],  hpl, top: h * 0.148, right: w * 0.18),       // ④ condenser right liquid
      _point(t[4],  hp,  top: h * 0.23, left: w * 0.315),        // ⑤ heat exchanger bottom
      _point(t[5],  lp,  top: h * 0.272, left: w * 0.03),        // ⑥ left blue line
      _point(t[6],  lp,  top: h * 0.275, left: w * 0.735),        // ⑦ LT compressor right
      _point(t[7],  hp,  top: h * 0.255, left: w * 0.655),        // ⑧ above R-404A
      _point(t[8],  hp,  top: h * 0.333, left: w * 0.38),        // ⑨ oil separator
      _point(t[9],  lpl, top: h * 0.18, left: w * 0.26),        // ⑩ heat exchanger top
      _point(t[10], hpl, top: h * 0.371, left: w * 0.175),        // ⑪ left yellow lower
      _point(t[11], lpl, top: h * 0.436, left: w * 0.36),        // ⑫ expansion valve lower
      _point(t[12], lp,  top: h * 0.433, right: w * 0.018),       // ⑬ PG1 right side
      _point(t[13], lpl, top: h * 0.49, right: w * 0.14),        // ⑭ evaporator inside
      _point(t[14], lpl, top: h * 0.54, right: w * 0.04),       // ⑮ evaporator bottom right
      _point(t[15], hpl, top: h * 0.51, right: w * 0.83),        // ⑯ bottom left
    ];
  }

  @override
  Widget build(BuildContext context) {
    final temps = _telemetry?.temps ?? List.filled(16, null);

    final connecting = _initialLoading && _telemetry == null;

    if (_noInternet) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1020),
        appBar: DashboardTopBar(
          deviceId: widget.deviceId,
          powerText: "Power: --",
          batteryText: "--%",
        ),
        body: const Center(
          child: Icon(Icons.wifi_off,
              size: 90, color: Colors.orangeAccent),
        ),
      );
    }

    Widget blinkingConnecting() {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.2, end: 1),
        duration: const Duration(milliseconds: 700),
        builder: (_, v, c) => Opacity(opacity: v, child: c),
        child: const Text(
          "CONNECTING...",
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: Colors.orangeAccent,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: DashboardTopBar(
        deviceId: widget.deviceId,
        powerText: "LOGGER",
        batteryText: isOnline ? "Online" : "Offline",
      ),
      body: RefreshIndicator(
        onRefresh: _manualRefresh,
        displacement: 80,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 24),
          child: Column(
            children: [

              /// 🔁 LAST SYNC + STATUS
              connecting
                  ? blinkingConnecting()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sync,
                            size: 14, color: Colors.white54),
                        const SizedBox(width: 6),
                        Text(
                          _storeTelemetry?.timestamp == null
                              ? "Last sync: --"
                              : "Last sync: ${_timeAgo(_storeTelemetry!.timestamp!)}",
                          style: TextStyle(
                            color: isStale
                                ? Colors.orangeAccent
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 18),

              /// 🌡️ SENSORS
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 16,
                itemBuilder: (_, i) {
                  final value =
                      temps[i]?.toStringAsFixed(1) ?? "--";

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: glassPill(
                      _names[i],
                      "$value °C",
                      () => _renameSensor(i),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _showDiagnoseImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Diagnose",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}