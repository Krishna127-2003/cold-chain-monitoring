// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/utils/responsive.dart';
import '../../routes/app_routes.dart';
import '../auth/google_auth_service.dart';

import '../../data/api/device_management_api.dart';
import '../../data/api/android_data_api.dart';
import '../../data/models/registered_device.dart';
import '../../data/session/session_manager.dart';
import 'package:flutter/services.dart';

import '../../core/ui/app_toast.dart';
import '../notifications/alert_manager.dart';
import 'dart:convert';
import '../../core/utils/battery_optimization.dart';
import '../dashboard/storage/telemetry_store.dart';
import '../../core/utils/battery_prompt_storage.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ NEW IMPORTS
import 'storage/datalogger_temp_store.dart';
import 'storage/selected_sensors_storage.dart';
import '../dashboard/storage/sensor_name_storage.dart';

class AllDevicesScreen extends StatefulWidget {
  const AllDevicesScreen({super.key});

  @override
  State<AllDevicesScreen> createState() => _AllDevicesScreenState();
}

class _AllDevicesScreenState extends State<AllDevicesScreen>
    with WidgetsBindingObserver {
  List<RegisteredDevice> _devices = [];
  bool _loadingDevices = true;

  String _welcomeName = "Guest";
  static const int offlineThresholdMinutes = 16;
  Timer? _deviceSyncTimer;
  String? _lastDeviceSnapshotHash;
  Timer? _tempTimer;

  final Set<String> _loadingTempDeviceIds = {};
  bool _tempsLoading = false;

  // ✅ Selected sensors per datalogger device
  final Map<String, List<int>> _selectedSensors = {};

  @override
  void initState() {
    super.initState();

    checkBatteryPopup();
    checkBattery();
    _loadWelcomeUser();
    _loadDevices();
    WidgetsBinding.instance.addObserver(this);

    _tempTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadTemps(),
    );

    _deviceSyncTimer = Timer.periodic(
      const Duration(seconds: 75),
      (_) => _loadDevices(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tempTimer?.cancel();
    _deviceSyncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDevices();
      _tempTimer?.cancel();
      _tempTimer = Timer.periodic(
        const Duration(seconds: 60),
        (_) => _loadTemps(),
      );
    }

    if (state == AppLifecycleState.paused) {
      _tempTimer?.cancel();
    }
  }

  Future<void> checkBattery() async {
    final allowed = await BatteryOptimization.isIgnoringOptimizations();
    if (!allowed) {
      await BatteryOptimization.requestDisableOnce();
    }
  }

  Future<void> checkBatteryPopup() async {
    final alreadyAsked = await BatteryPromptStorage.wasShown();
    if (alreadyAsked) return;

    final ignored = await BatteryOptimization.isIgnoringOptimizations();
    if (!ignored) {
      await BatteryOptimization.requestDisableOnce();
    }

    await BatteryPromptStorage.markShown();
  }

  Future<void> _sendForgotPinEmail(RegisteredDevice device) async {
    final email = await SessionManager.getEmail() ?? "unknown";

    final subject = "Forgot Device PIN – ${device.deviceId}";
    final body = "User Email: $email\n"
        "Device ID: ${device.deviceId}\n"
        "Device Type: ${device.serviceType}\n"
        "Department: ${device.department}\n"
        "Area: ${device.area}\n"
        "\n"
        "Request Time: ${DateTime.now()}\n"
        "\n"
        "Please assist in retrieving or resetting the device PIN.";

    final uri = Uri.parse(
      'mailto:IotAppSupport@markenworld.com'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _loadWelcomeUser() async {
    final loginType = await SessionManager.getLoginType();
    if (loginType == "google") {
      final user = GoogleAuthService.currentUser();
      final name = user?.displayName;
      if (name != null && name.isNotEmpty) {
        setState(() => _welcomeName = name.split(" ").first);
        return;
      }
    }
    setState(() => _welcomeName = "Guest");
  }

  RegisteredDevice _mapApiRow(Map<String, dynamic> row, String email) {
    return RegisteredDevice(
      email: email,
      loginType: "google",
      deviceId: (row["deviceId"] ?? "").toString(),
      qrCode: (row["deviceId"] ?? "").toString(),
      productKey: (row["deviceProductKey"] ?? "").toString(),
      displayName:
          (row["deviceDisplayName"] ?? row["deviceName"] ?? "").toString(),
      department: (row["deviceDeptName"] ?? "").toString(),
      area: (row["deviceAreaRoom"] ?? "").toString(),
      pinHash: (row["devicePin"] ?? "").toString(),
      serviceType: (row["deviceType"] ?? "").toString(),
      registeredAt: DateTime.now().toUtc(),
      deviceNumber: 0,
      modeOp: "",
    );
  }

  Future<void> _loadDevices() async {
    setState(() => _loadingDevices = true);

    final email = await SessionManager.getEmail();
    if (email == null || email.isEmpty) {
      setState(() {
        _devices = [];
        _loadingDevices = false;
      });
      return;
    }

    try {
      final rows = await DeviceManagementApi.listDevices(email);
      final snapshot = jsonEncode(rows);
      if (snapshot == _lastDeviceSnapshotHash) {
        setState(() => _loadingDevices = false);
        return;
      }
      _lastDeviceSnapshotHash = snapshot;

      final mapped = rows
          .whereType<Map>()
          .map((e) => _mapApiRow(Map<String, dynamic>.from(e), email))
          .where((d) => d.deviceId.trim().isNotEmpty)
          .toList();

      setState(() {
        _devices = mapped;
        _loadingDevices = false;
      });

      // ✅ Load selected sensors for dataloggers
      await _loadSelectedSensors();
      await _loadTemps();
    } catch (_) {
      setState(() => _loadingDevices = false);
    }
  }

  // ✅ Load persisted sensor selections for all datalogger devices
  Future<void> _loadSelectedSensors() async {
    for (final d in _devices) {
      if (d.serviceType == 'DATA_LOGGER_ULT') {
        final indices = await SelectedSensorsStorage.load(d.deviceId);
        if (mounted) {
          setState(() => _selectedSensors[d.deviceId] = indices);
        }
      }
    }
  }

  Future<void> _loadTemps() async {
    if (_devices.isEmpty || _tempsLoading) return;

    _tempsLoading = true;

    setState(() {
      _loadingTempDeviceIds
        ..clear()
        ..addAll(_devices.map((d) => d.deviceId.trim()));
    });

    try {
      await Future.wait(
        _devices.map((device) async {
          final id = device.deviceId.trim();

          try {
            if (device.serviceType == 'DATA_LOGGER_ULT') {
              // ✅ Datalogger: fetch 16-sensor data
              final t = await AndroidDataApi.fetchDatalogger(id);
              if (t != null) {
                DataloggerTempStore.set(id, t.temps);
                if (!_selectedSensors.containsKey(id)) {
                  final indices = await SelectedSensorsStorage.load(id);
                  if (mounted) {
                    setState(() => _selectedSensors[id] = indices);
                  }
                }
                if (mounted) setState(() {});
              }
            } else {
              // ✅ Normal device: existing logic
              final t = await AndroidDataApi.fetchByDeviceId(id);
              if (t != null) {
                if (!mounted) return;
                setState(() {
                  TelemetryStore.set(id, t);
                });

                await AlertManager.handleTelemetry(
                  deviceId: id,
                  equipmentType: device.serviceType,
                  temperature: t.pv,
                  sv: t.sv,
                  batteryPercent: t.battery,
                  powerFail: !t.powerOn,
                  probeFail: !t.probeOk,
                  systemError: !t.systemHealthy,
                );
              }
            }
          } catch (_) {}

          setState(() => _loadingTempDeviceIds.remove(id));
        }),
      );
    } finally {
      _tempsLoading = false;
    }
  }

  Future<String?> _askPin(RegisteredDevice device) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final controller = TextEditingController();

        return AlertDialog(
          title: const Text("Verify PIN"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Device: ${device.deviceId}"),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Enter 4-digit PIN",
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _sendForgotPinEmail(device);
                  },
                  child: const Text(
                    "Forgot PIN?",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx, controller.text.trim());
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  bool isDeviceOnline(String id) {
    final t = TelemetryStore.get(id);
    if (t?.timestamp == null) return false;
    return DateTime.now().difference(t!.timestamp!).inMinutes <=
        offlineThresholdMinutes;
  }

  String _systemStatus(String id) {
    final t = TelemetryStore.get(id);
    if (t == null) return "--";
    return t.systemHealthy ? "HEALTHY" : "FAILURE";
  }

  String? _temp(String id) {
    final t = TelemetryStore.get(id);
    if (t?.pv == null) return null;
    return t!.pv!.toStringAsFixed(1);
  }

  Future<void> _logout() async {
    await GoogleAuthService.signOut();
    await SessionManager.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.auth,
      (r) => false,
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _logout();
    }
  }

  void _showDeviceActions(RegisteredDevice device) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Device"),
                onTap: () async {
                  Navigator.pop(ctx);
                  final updated = await Navigator.pushNamed(
                    context,
                    AppRoutes.editDevice,
                    arguments: device,
                  );
                  if (updated == true) {
                    await _loadDevices();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete Device"),
                onTap: () async {
                  Navigator.pop(ctx);
                  final pin = await _askPin(device);
                  if (pin == null || pin.isEmpty) return;

                  final email = await SessionManager.getEmail();
                  if (email == null) return;

                  final result = await DeviceManagementApi.deleteDevice(
                    email: email,
                    deviceId: device.deviceId,
                    devicePin: pin,
                  );

                  if (result.success) {
                    await _loadDevices();
                  } else {
                    if (!mounted) return;
                    AppToast.show(result.message);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Datalogger temp row — shows selected sensors or prompt to select
  Widget _dataloggerTempRow(String deviceId, bool loading) {
    final selected = _selectedSensors[deviceId] ?? [];
    final temps = DataloggerTempStore.get(deviceId);

    if (loading && temps == null) {
      return const Text(
        "Temp: loading...",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      );
    }

    if (selected.isEmpty) {
      return GestureDetector(
        onTap: () => _selectSensors(deviceId),
        child: Row(
          children: const [
            Icon(Icons.touch_app, size: 14, color: Colors.blue),
            SizedBox(width: 4),
            Text(
              "Tap to select sensors",
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final parts = selected.map((i) {
      final val = (temps != null && i < temps.length) ? temps[i] : null;
      final label = "S${i + 1}";
      final valStr = val != null ? "${val.toStringAsFixed(1)}°C" : "--°C";
      return "$label: $valStr";
    }).join("   |   ");

    return Row(
      children: [
        Expanded(
          child: Text(
            parts,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _selectSensors(deviceId),
          child: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.edit, size: 14, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // ✅ Dialog to pick up to 2 sensors
  Future<void> _selectSensors(String deviceId) async {
    final names = await Future.wait(
      List.generate(16, (i) => SensorNameStorage.getName(deviceId, i + 1)),
    );

    final current = List<int>.from(_selectedSensors[deviceId] ?? []);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlg) => AlertDialog(
            title: const Text("Select up to 2 sensors"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 16,
                itemBuilder: (_, i) {
                  final isSelected = current.contains(i);
                  return CheckboxListTile(
                    dense: true,
                    title: Text("${i + 1}. ${names[i]}"),
                    value: isSelected,
                    onChanged: (v) {
                      setDlg(() {
                        if (v == true) {
                          if (current.length < 2) current.add(i);
                        } else {
                          current.remove(i);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await SelectedSensorsStorage.save(deviceId, current);
                  if (mounted) {
                    setState(() => _selectedSensors[deviceId] = List.from(current));
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = _devices;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: SvgPicture.asset("assets/images/marken_logo.svg", height: 34),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.alertHistory);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.services);
          await _loadDevices();
        },
        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.pad(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Text(
              "Saved Devices",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              "Welcome, $_welcomeName",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _loadingDevices
                  ? const Center(child: CircularProgressIndicator())
                  : devices.isEmpty
                      ? _emptyState(context)
                      : ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (_, i) {
                            final d = devices[i];
                            final id = d.deviceId.trim();
                            final telemetry = TelemetryStore.get(id);
                            final loading = _loadingTempDeviceIds.contains(id);
                            final isDataLogger =
                                d.serviceType == 'DATA_LOGGER_ULT';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.dashboard,
                                    arguments: {
                                      "deviceId": id,
                                      "equipmentType": d.serviceType,
                                    },
                                  );
                                },
                                onLongPress: () {
                                  HapticFeedback.mediumImpact();
                                  _showDeviceActions(d);
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 46,
                                          width: 46,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.12),
                                          ),
                                          child: Icon(
                                            _iconForType(d.serviceType),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      id,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      _StatusChip(
                                                        status:
                                                            _systemStatus(id),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.notifications_active_outlined,
                                                          size: 20,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.pushNamed(
                                                            context,
                                                            AppRoutes
                                                                .notificationSettings,
                                                            arguments: {
                                                              "deviceId": id,
                                                              "equipmentType":
                                                                  d.serviceType,
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                [
                                                  d.displayName,
                                                  d.department,
                                                  if (d.area.trim().isNotEmpty &&
                                                      d.area != "Unknown")
                                                    d.area,
                                                ].join(" • "),
                                              ),
                                              Text(
                                                d.serviceType
                                                    .replaceAll("_", " "),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                              const SizedBox(height: 6),

                                              // ✅ TEMP ROW — datalogger vs normal
                                              Row(
                                                children: [
                                                  if (isDataLogger)
                                                    Expanded(
                                                      child: _dataloggerTempRow(
                                                          id, loading),
                                                    )
                                                  else
                                                    Text(
                                                      loading &&
                                                              telemetry == null
                                                          ? "Temp: loading..."
                                                          : telemetry == null
                                                              ? "No data available"
                                                              : "Temp: ${_temp(id)} °C",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: telemetry == null
                                                            ? Colors.grey
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                      ),
                                                    ),
                                                  const SizedBox(width: 8),
                                                  // Online badge
                                                  if (isDataLogger)
                                                    _onlineBadge(
                                                      DataloggerTempStore.get(
                                                              id) !=
                                                          null,
                                                    )
                                                  else if (telemetry != null)
                                                    _onlineBadge(
                                                        isDeviceOnline(id)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _onlineBadge(bool online) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: online
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: online ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(Icons.circle,
              size: 7, color: online ? Colors.green : Colors.red),
          const SizedBox(width: 4),
          Text(
            online ? "Online" : "Offline",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: online ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.devices, size: 48),
              SizedBox(height: 12),
              Text("No devices yet"),
              SizedBox(height: 6),
              Text("Tap + to add your first device."),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case "DEEP_FREEZER":
        return Icons.ac_unit;
      case "BBR":
        return Icons.medical_services_outlined;
      case "PLATELET":
        return Icons.science_outlined;
      case "WALK_IN_COOLER":
        return Icons.warehouse_outlined;
      default:
        return Icons.device_thermostat;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c = Colors.grey;
    if (status.contains("FAIL")) c = Colors.red;
    if (status == "HEALTHY") c = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        status,
        style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w800, color: c),
      ),
    );
  }
}