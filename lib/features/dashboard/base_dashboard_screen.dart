// ignore_for_file: unnecessary_type_check
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/api/android_data_api.dart';
import 'widgets/dashboard_top_bar.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'models/unified_telemetry.dart';
import '../../data/api/immediate_send_api.dart';
import '../dashboard/storage/telemetry_store.dart';

class Pill {
  final String label;
  final String value;
  Pill(this.label, this.value);

}

class BaseDashboardScreen extends StatefulWidget {
  final String deviceId;
  final String title;
  final List<Pill> Function(UnifiedTelemetry t) buildPills;

  const BaseDashboardScreen({
    super.key,
    required this.deviceId,
    required this.title,
    required this.buildPills,
  });

  @override
  State<BaseDashboardScreen> createState() => _BaseDashboardScreenState();
}

class _BaseDashboardScreenState extends State<BaseDashboardScreen>
    with SingleTickerProviderStateMixin {

  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  UnifiedTelemetry? get _t =>
    TelemetryStore.get(widget.deviceId);
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _noInternet = false;
  DateTime? _lastManualRefresh;
  late AnimationController _refreshController;
  static const int _offlineThresholdMinutes = 16;


  // ================= TIME =================

  bool isStale() =>
    _t?.timestamp == null ||
    DateTime.now().difference(_t!.timestamp!).inMinutes >
        _offlineThresholdMinutes;
  
  bool isOnline() {
    if (_t?.timestamp == null) return false;
    return DateTime.now().difference(_t!.timestamp!).inMinutes <=
        _offlineThresholdMinutes;
  }

  bool get hasNoData =>
    !_initialLoading && _t == null && !_noInternet;

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);

    // 🔥 NEW LOGIC
    if (d.inSeconds < 50) {
      return "a few seconds ago";
    }

    if (d.inSeconds < 60) {
      return "1 min ago";
    }

    if (d.inMinutes < 60) {
      return "${d.inMinutes} min ago";
    }

    if (d.inHours < 24) {
      return "${d.inHours} hrs ago";
    }

    return "${d.inDays} days ago";
  }

  // ================= FETCH =================

  Future<void> _fetch({bool isRefresh = false}) async {
    if (_refreshing) return;

    if (isRefresh) {
      _refreshing = true;
    } else if (_t?.timestamp == null) {
      _initialLoading = true; // only first load shows CONNECTING
    }

    if (mounted) setState(() {});

    try {
      final telemetry = await AndroidDataApi
          .fetchByDeviceId(widget.deviceId)
          .timeout(const Duration(seconds: 6));

      if (!mounted) return;

      if (telemetry != null) {
       TelemetryStore.set(widget.deviceId, telemetry);
      }

      _noInternet = false;
    } catch (e) {
      _noInternet = true;
    }

    _initialLoading = false;
    _refreshing = false;

    if (mounted) setState(() {});

  }

  void _listenToConnectivity() {
    _connectivitySub =
      Connectivity().onConnectivityChanged.listen((results) {

    final hasInternet = !results.contains(ConnectivityResult.none);


      if (hasInternet && _noInternet) {
        if (!mounted) return;
        setState(() => _noInternet = false);
        _fetch();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Connected — refreshing data"),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _manualRefresh() async {
    if (!mounted) return;
    _refreshController.repeat();

    final now = DateTime.now();

    if (_lastManualRefresh == null ||
        now.difference(_lastManualRefresh!).inSeconds >= 20) {
      _lastManualRefresh = now;
      await _fetch(isRefresh: true);
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
    }

    if (!mounted) return;
    _refreshController.stop();
    _refreshController.reset();
  }

  @override
  void initState() {
    super.initState();

    ImmediateSendApi.trigger(widget.deviceId); // one-time kick

    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fetch();
    _listenToConnectivity();
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

  // ================= UI HELPERS =================

  Widget noInternetView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.wifi_off, size: 90, color: Colors.orangeAccent),
        SizedBox(height: 14),
        Text(
          "No Internet Connection",
          style: TextStyle(
            color: Colors.orangeAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text(
          "Please check your network",
          style: TextStyle(color: Colors.white54),
        )
      ],
    );
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
            ),
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
    final t = TelemetryStore.get(widget.deviceId);
    final bool connecting = _initialLoading;
    final bool noData = hasNoData;
    final pvText = (t?.pv == null) ? "--.-" : t!.pv!.toStringAsFixed(1);
    final svText = (t?.sv == null) ? "--.-" : t!.sv!.toStringAsFixed(1);

    if (_noInternet) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1020),
        appBar: DashboardTopBar(
          deviceId: widget.deviceId,
          powerText: "Power: --",
          batteryText: "--%",
        ),
        body: Center(child: noInternetView()),
      );
    }

    Widget blinkingConnecting() {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.2, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
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
        powerText: (connecting || noData)
            ? "Power: --"
            : "Power: ${t!.powerOn ? "ON" : "OFF"}",

        batteryText: (connecting || noData)
            ? "--%"
            : "${t!.battery}%",
      ),
      body: RefreshIndicator(
        onRefresh: _manualRefresh,
        displacement: 80,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 40, 14, 24),
          child: Column(
            children: [
              glassCard(
                Column(
                  children: [
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        letterSpacing: 2,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      connecting
                          ? "--.- °C"
                          : noData
                              ? "— —"
                              : "$pvText °C",
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
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        connecting
                            ? "SET --.- °C"
                            : noData
                                ? "SET — —"
                                : "SET $svText °C",
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
                          _t?.timestamp == null
                              ? "Last sync: Connecting..."
                              : "Last sync: ${_timeAgo(t!.timestamp!)}",
                          style: TextStyle(
                            color: isStale()
                                ? Colors.orangeAccent
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "DEVICE ID : ${widget.deviceId}",
                          style: const TextStyle(color: Colors.white38),
                        ),

                        const SizedBox(width: 8),

                        if (!connecting && !noData)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOnline()
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isOnline() ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: isOnline() ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline() ? "Online" : "Offline",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOnline() ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              glassCard(
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: connecting
                          ? blinkingConnecting()
                          : noData
                              ? const Text(
                                  "NO DATA AVAILABLE",
                                  style: TextStyle(
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey,
                                  ),
                                )
                              : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "SYSTEM",
                            style: TextStyle(
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            t!.systemHealthy ? "HEALTHY" : "FAILURE",
                            style: TextStyle(
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              color: t.systemHealthy
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!connecting && !noData)
                      ...widget
                          .buildPills(t!)
                          .map((p) => pillRow(p.label, p.value)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
