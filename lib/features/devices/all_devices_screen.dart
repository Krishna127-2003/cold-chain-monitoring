// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:async';

import '../../core/utils/responsive.dart';
import '../../data/storage/local_device_store.dart';
import '../../routes/app_routes.dart';
import '../auth/google_auth_service.dart';
import '../../data/api/android_data_api.dart';

class AllDevicesScreen extends StatefulWidget {
  const AllDevicesScreen({super.key});

  @override
  State<AllDevicesScreen> createState() => _AllDevicesScreenState();
}

class _AllDevicesScreenState extends State<AllDevicesScreen> {
  bool _isEditMode = false;

  /// selected deviceIds
  final Set<String> _selected = {};

  /// ✅ FIX A) Prevent multiple redirects loop
  bool _didAutoRedirect = false;

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

  void _selectAll(List<Map<String, dynamic>> devices) {
    setState(() {
      _selected.clear();
      for (final d in devices) {
        final id = (d["deviceId"] ?? "").toString();
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

    _loadTemps();

    // ✅ refresh every 60 seconds when saved devices screen is open
    _tempTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _loadTemps();
    });
  }

  @override
  void dispose() {
    _tempTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTemps() async {
    setState(() => _loadingTemps = true);

    final data = await AndroidDataApi.fetchLatest();

    if (!mounted) return;

    setState(() {
      _latestData = data ?? {};
      _loadingTemps = false;
    });
  }

  /// ✅ ONLY REQUIRED ADDITION: Helper to get temp from API response
  String? _getTempForDevice(String deviceId) {
    // CASE 1: API returns list of devices
    if (_latestData["devices"] is List) {
      final list = _latestData["devices"] as List;
      for (final item in list) {
        if (item is Map) {
          final id = (item["deviceId"] ?? item["id"] ?? "").toString();
          if (id == deviceId) {
            final t = item["temp"] ?? item["temperature"];
            if (t == null) return null;
            return t.toString();
          }
        }
      }
    }

    // CASE 2: API returns map keyed by deviceId
    if (_latestData[deviceId] is Map) {
      final d = _latestData[deviceId] as Map;
      final t = d["temp"] ?? d["temperature"];
      if (t == null) return null;
      return t.toString();
    }

    return null;
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
    List<Map<String, dynamic>> currentDevices,
  ) async {
    if (_selected.isEmpty) return;

    final ok = await _confirmDelete(context, _selected.length);
    if (!ok) return;

    // ✅ Backup deleted devices for Undo
    final deletedBackup = currentDevices
        .where((d) => _selected.contains((d["deviceId"] ?? "").toString()))
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // ✅ FIX: Delete globally (because AllDevicesScreen has devices from ALL equipment types)
    for (final id in _selected) {
      await LocalDeviceStore.deleteDeviceGlobal(deviceId: id);
    }

    // ✅ Exit edit mode and refresh
    setState(() {
      _isEditMode = false;
      _selected.clear();
    });

    // ✅ Undo SnackBar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5), // ✅ auto dismiss
        content: Text("${deletedBackup.length} device(s) deleted ✅"),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () async {
            ScaffoldMessenger.of(context).hideCurrentSnackBar(); // ✅ close instantly
            for (final d in deletedBackup) {
              await LocalDeviceStore.addDevice(d);
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await GoogleAuthService.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.auth,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pad(context);
    final devices = LocalDeviceStore.getDevices();

    /// ✅ FIX A) Auto redirect to ServicesScreen when empty
    if (devices.isEmpty && !_didAutoRedirect && !_isEditMode) {
      _didAutoRedirect = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.services,
        );
      });
    }

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
            onPressed: _logout,
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
                // ✅ Add device flow goes via Services screen
                Navigator.pushNamed(
                  context,
                  AppRoutes.services,
                );
              },
              child: const Icon(Icons.add),
            ),

      body: Padding(
        padding: EdgeInsets.all(padding),
        child: devices.isEmpty
            ? _emptyState(context)
            : ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final d = devices[index];

                  final deviceId = (d["deviceId"] ?? "-").toString();
                  final deviceName =
                      (d["deviceName"] ?? "Unnamed Device").toString();
                  final dept = (d["department"] ?? "-").toString();
                  final equipmentType = (d["equipmentType"] ?? "-").toString();
                  final status = (d["status"] ?? "NORMAL").toString();

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
                                      .withOpacity(0.12),
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
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
    if (s.toUpperCase().contains("FAIL")) return Colors.red;
    if (s.toUpperCase().contains("ALARM")) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.35)),
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