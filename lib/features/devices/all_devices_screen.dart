// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:async';

import '../../core/utils/responsive.dart';
import '../../routes/app_routes.dart';
import '../auth/google_auth_service.dart';
import '../../data/api/android_data_api.dart';
import '../../data/repository/device_repository.dart';
import '../../data/repository_impl/local_device_repository.dart';
import '../../data/session/session_manager.dart';
import '../../data/models/registered_device.dart';


class AllDevicesScreen extends StatefulWidget {
  const AllDevicesScreen({super.key});

  @override
  State<AllDevicesScreen> createState() => _AllDevicesScreenState();
  
}

class _AllDevicesScreenState extends State<AllDevicesScreen> {

  final DeviceRepository _deviceRepo = LocalDeviceRepository();
  List<RegisteredDevice> _devices = [];
  bool _loadingDevices = true;

  bool _isEditMode = false;

  /// selected deviceIds
  final Set<String> _selected = {};

  /// ✅ FIX A) Prevent multiple redirects loop
  Timer? _tempTimer;
  Map<String, dynamic> _latestData = {};
  bool _loadingTemps = false;

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      _selected.clear();
    });
  }

  void _toggleSelection(String deviceId) {
    setState(() {
      if (_selected.contains(deviceId)) {
        _selected.remove(deviceId);
      } else {
        _selected.add(deviceId);
      }
    });
  }

  void _selectAll(List<RegisteredDevice> devices) {
    setState(() {
      _selected.clear();
      for (final d in devices) {
        final id = d.deviceId;
        if (id.isNotEmpty) _selected.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  @override
  void initState() {
    super.initState();

    _loadDevices(); // 👈 ADD THIS

    // ✅ refresh every 60 seconds when saved devices screen is open
    _tempTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted || _devices.isEmpty) return;
      await _loadTemps();
    });
  }

  @override
  void dispose() {
    _tempTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? _getDeviceData(String deviceId) {
    if (_latestData.isEmpty) return null;

    final apiDeviceId =
        (_latestData["device_id"] ?? "").toString();

    if (apiDeviceId == deviceId) {
      return _latestData;
    }

    return null;
  }

  Future<void> _loadDevices() async {
    setState(() => _loadingDevices = true);

    final loginType = await SessionManager.getLoginType();
    final email = await SessionManager.getEmail();

    final devices = await _deviceRepo.getRegisteredDevices(
      email: email ?? "",
      loginType: loginType ?? "guest",
    );

    if (!mounted) return;

    setState(() {
      _devices = devices;
      _loadingDevices = false;
    });

    // ✅ IMPORTANT: load temps ONLY AFTER devices are ready
    await _loadTemps();
  }

  void _hideSnackBar() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.removeCurrentSnackBar(); // instant kill
  }

  Future<void> _loadTemps() async {
    if (!mounted) return;

    // ✅ SAFETY: devices not loaded yet
    if (_devices.isEmpty) {
      debugPrint("⏸ Skipping temp load: no devices yet");
      return;
    }

    setState(() => _loadingTemps = true);

    // ✅ TEMP: only fetch known working device
    final workingDevice = _devices.firstWhere(
      (d) => d.deviceId == "5191",
      orElse: () => _devices.first,
    );

    final rawId = workingDevice.deviceId;

    // ✅ extract numeric deviceId if URL was stored
    final deviceId = rawId.contains("device_id=")
        ? Uri.parse(rawId).queryParameters["device_id"]
        : rawId;

    if (deviceId == null) {
      debugPrint("❌ Invalid deviceId: $rawId");
      return;
    }

    final data = await AndroidDataApi.fetchByDeviceId(deviceId);

    if (!mounted) return;

    setState(() {
      _latestData = data ?? {};
      _loadingTemps = false;
    });
  }


  String _getSystemStatusForDevice(String deviceId) {
    final d = _getDeviceData(deviceId);
    if (d == null) return "--";

    final error = d["Error"] ?? d["error"] ?? "0";

    return error.toString() == "0" ? "HEALTHY" : "FAILURE";
  }

  String? _getTempForDevice(String deviceId) {
    final d = _getDeviceData(deviceId);
    if (d == null) return null;

    // Dynamic priority:
    // temp → pv → sv
    final temp = d["temp"] ?? d["pv"] ?? d["sv"];
    return temp?.toString();
  }


  Future<bool> _confirmDelete(BuildContext context, int count) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete device(s)?"),
        content: Text(
          "You are about to delete $count device(s) from Saved Devices.\n\nYou can UNDO immediately after deleting.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _deleteSelectedDevices(
    List<RegisteredDevice> currentDevices,
  ) async {
    if (_selected.isEmpty) return;

    final ok = await _confirmDelete(context, _selected.length);
    if (!ok) return;

    // ✅ Backup deleted devices for Undo
    final deletedBackup = currentDevices
      .where((d) => _selected.contains(d.deviceId))
      .toList();


    // ✅ FIX: Delete globally (because AllDevicesScreen has devices from ALL equipment types)
    for (final id in _selected) {
      await _deviceRepo.deleteDevice(id);
    }

    // ✅ Exit edit mode and refresh
    setState(() {
      _devices.removeWhere(
        (d) => _selected.contains(d.deviceId),
      );
      _isEditMode = false;
      _selected.clear();
    });

    // ✅ Undo SnackBar (production-grade)
    _hideSnackBar(); // 1️⃣ kill any existing snackbar first

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4), // 2️⃣ auto-dismiss after 4 sec
        behavior: SnackBarBehavior.floating,
        content: Text("${deletedBackup.length} device(s) deleted ✅"),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () async {
            _hideSnackBar(); // 3️⃣ disappear immediately on UNDO

            for (final d in deletedBackup) {
              await _deviceRepo.registerDevice(d);
            }

            await _loadDevices(); // 4️⃣ refresh UI
          },
        ),
      ),
    );
  }

  Future<void> _logout() async {
    _hideSnackBar(); // 🔥 kill snackbar before leaving screen

    await GoogleAuthService.signOut();
    await SessionManager.logout(); // ✅ CLEAR SESSION

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.auth,
      (route) => false,
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text(
          "Are you sure you want to logout?\nYou will need to sign in again.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _logout();
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pad(context);
    final devices = _devices;

    return Scaffold(
      appBar: AppBar(
        title: _isEditMode
            ? Text("${_selected.length} selected")
            : const Text("Saved Devices"),
        actions: [
          // ✅ Edit mode button (only if devices exist)
          if (devices.isNotEmpty)
            IconButton(
              icon: Icon(_isEditMode ? Icons.close : Icons.edit),
              tooltip: _isEditMode ? "Exit edit mode" : "Edit devices",
              onPressed: _toggleEditMode,
            ),

          // ✅ Edit mode actions
          if (_isEditMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: "Select All",
              onPressed: () => _selectAll(devices),
            ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: "Clear Selection",
              onPressed: _clearSelection,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Delete Selected",
              onPressed: _selected.isEmpty
                  ? null
                  : () => _deleteSelectedDevices(devices),
            ),
          ],

          // ✅ Logout always available
          IconButton(
            onPressed: () => _showLogoutConfirm(context),
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),

      // ✅ FAB ONLY in non-edit mode
      floatingActionButton: _isEditMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                _hideSnackBar(); // ✅ kill snackbar

                Navigator.pushNamed(
                  context,
                  AppRoutes.services,
                );
              },
              child: const Icon(Icons.add),
            ),

      body: Padding(
        padding: EdgeInsets.all(padding),
        child: _loadingDevices
            ? const Center(child: CircularProgressIndicator())
            : devices.isEmpty
                ? _emptyState(context)
                : ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final d = devices[index];

                  final deviceId = d.deviceId;
                  final deviceName = d.deviceId; // until you add a name field
                  final dept = "-";              // placeholder
                  final equipmentType = d.serviceType;
                  final status = _getSystemStatusForDevice(deviceId);
                  debugPrint("SavedDevices device=$deviceId data=${_getDeviceData(deviceId)}");

                  final selected = _selected.contains(deviceId);

                  // ✅ ONLY REQUIRED ADDITION: live temp read
                  final liveTemp = _getTempForDevice(deviceId);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        if (_isEditMode) {
                          _toggleSelection(deviceId);
                        } else {
                          _hideSnackBar(); // ✅ kill snackbar on screen change

                          Navigator.pushNamed(
                            context,
                            AppRoutes.dashboard,
                            arguments: {
                              "deviceId": deviceId,
                              "equipmentType": equipmentType,
                            },
                          );
                        }
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isEditMode) ...[
                                Checkbox(
                                  value: selected,
                                  onChanged: (_) => _toggleSelection(deviceId),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Container(
                                height: 46,
                                width: 46,
                                  decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.12),
                                ),
                                child: Icon(
                                  _iconForType(equipmentType),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            deviceName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (!_isEditMode)
                                          _StatusChip(status: status),

                                          if (!_isEditMode) ...[
                                          const SizedBox(width: 6),

                                          IconButton(
                                            icon: const Icon(Icons.notifications_active_outlined),
                                            tooltip: "Notification settings",
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                AppRoutes.notificationSettings,
                                                arguments: {
                                                  "deviceId": deviceId,
                                                },
                                              );
                                            },
                                          ),
                                        ]
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "$equipmentType • $dept",
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Device ID: $deviceId",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),

                                    // ✅ ONLY REQUIRED ADDITION: TEMP LINE
                                    const SizedBox(height: 6),
                                    Text(
                                      _loadingTemps
                                          ? "Temp: loading..."
                                          : "Temp: ${liveTemp ?? "--"} °C",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: liveTemp == null
                                                ? const Color(0xFF64748B)
                                                : Colors.blue,
                                          ),
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
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.devices,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "No devices yet",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                "Tap + to add your first device.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
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

  Color _color(String s) {
    final v = s.toUpperCase();

    if (v == "--") return Colors.grey;
    if (v.contains("FAIL")) return Colors.red;
    if (v.contains("UNKNOWN")) return Colors.grey;

    return Colors.green;
  }


  @override
  Widget build(BuildContext context) {
    final c = _color(status);

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
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: c,
        ),
      ),
    );
  }
}