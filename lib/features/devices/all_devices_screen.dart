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
import '../dashboard/models/unified_telemetry.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/api/account_deletion_api.dart';
import '../../data/api/user_activity_api.dart';
import '../devices/security/pin_verify_dialog.dart';

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
  String _welcomeName = "Guest";

  /// selected deviceIds
  final Set<String> _selected = {};

  /// ✅ FIX A) Prevent multiple redirects loop
  Timer? _tempTimer;
  final Map<String, UnifiedTelemetry> _telemetryByDevice = {};
  final Set<String> _loadingTempDeviceIds = {};

  bool isDeviceOnline(String deviceId) {
    final t = _telemetryByDevice[deviceId];
    if (t?.timestamp == null) return false;

    return DateTime.now().difference(t!.timestamp!).inMinutes <= 5;
  }

  bool hasNoData(String deviceId) {
    return _telemetryByDevice[deviceId] == null;
  }

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

    _loadWelcomeUser(); // 👈 ADD THIS
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

  Future<void> _loadWelcomeUser() async {
    final loginType = await SessionManager.getLoginType();

    if (loginType == "google") {
      final user = GoogleAuthService.currentUser();
      final fullName = user?.displayName;

      if (fullName != null && fullName.trim().isNotEmpty) {
        final firstName = fullName.split(" ").first;
        setState(() {
          _welcomeName = firstName;
        });
        return;
      }
    }

    // fallback (guest or unknown)
    setState(() {
      _welcomeName = "Guest";
    });
  }

  // NOTE: telemetry is stored in `_latestTelemetry` (UnifiedTelemetry)

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
    if (!mounted || _devices.isEmpty) return;

    final ids = _devices
        .map((d) => _normalizeDeviceId(d.deviceId))
        .where((id) => id.isNotEmpty)
        .toSet();

    if (ids.isEmpty) return;

    setState(() {
      _loadingTempDeviceIds
        ..clear()
        ..addAll(ids);
    });

    await Future.wait(
      ids.map((deviceId) async {
        final telemetry = await AndroidDataApi.fetchByDeviceId(deviceId);
        if (!mounted) return;

        setState(() {
          _loadingTempDeviceIds.remove(deviceId);
          if (telemetry != null) {
            _telemetryByDevice[deviceId] = telemetry;
          }
        });
      }),
    );
  }

  String _getSystemStatusForDevice(String deviceId) {
    final t = _telemetryByDevice[deviceId];
    if (t == null) return "--";
    return t.systemHealthy ? "HEALTHY" : "FAILURE";
  }

  String? _getTempForDevice(String deviceId) {
    final t = _telemetryByDevice[deviceId];
    if (t?.pv == null) return null;
    return t!.pv!.toStringAsFixed(1);
  }

  String _normalizeDeviceId(String rawId) {
    return rawId.trim();
  }


  Future<void> _deleteSelectedDevices(
    List<RegisteredDevice> currentDevices,
  ) async {
    if (_selected.isEmpty) return;

    final verified = await PinVerifyDialog.verify(
      context,
      deviceId: _selected.first,
    );

    if (!verified) return;

    // ✅ Backup deleted devices for Undo
    final deletedBackup = currentDevices
        .where((d) => _selected.contains(d.deviceId))
        .toList();

    // ✅ FIX: Delete globally (because AllDevicesScreen has devices from ALL equipment types)
    for (final id in _selected) {
      await _deviceRepo.deleteDevice(id);

      final email = await SessionManager.getEmail();

      if (email != null) {
        await UserActivityApi.sendAction(
          email: email,
          action: "device_deleted",
          deviceId: id,
        );
      }
    }

    // ✅ Exit edit mode and refresh
    setState(() {
      _devices.removeWhere((d) => _selected.contains(d.deviceId));
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
    _hideSnackBar();

    final email = await SessionManager.getEmail();

    if (email != null) {
      await UserActivityApi.sendAction(email: email, action: "logout");
    }

    await GoogleAuthService.signOut();
    await SessionManager.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.auth,
      (route) => false,
    );
  }

  Future<void> _deleteAccountCompletely() async {
    final email = await SessionManager.getEmail();

    if (email == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Email not found")));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete account permanently"),
        content: const Text(
          "This will delete all your data forever. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete forever"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await AccountDeletionApi.sendPermanentDeleteCommand(email);

    if (success) {
      await UserActivityApi.sendAction(
        email: email,
        action: "permanently_delete",
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted successfully")),
      );

      await _logout();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to delete account")));
    }
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Account options"),
        content: const Text("Choose what you want to do"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
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
    //final padding = Responsive.pad(context);
    final devices = _devices;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56, // 👈 smaller than default 56
        automaticallyImplyLeading: false,
        elevation: 0, // cleaner look (optional)
        // 🎯 This forces the title to the absolute center
        title: SvgPicture.asset(
            "assets/images/marken_logo.svg",
            height: 34,
          ),
          centerTitle: false,

        // 🎯 Use the flexibleSpace or a separate Stack if you want the title
        // to ignore the width of the logo entirely:
        actions: [
          const SizedBox(width: 4),
          if (devices.isNotEmpty)
            IconButton(
              icon: Icon(_isEditMode ? Icons.close : Icons.edit),
              onPressed: _toggleEditMode,
            ),

          if (_isEditMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () => _selectAll(devices),
            ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearSelection,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selected.isEmpty
                  ? null
                  : () => _deleteSelectedDevices(devices),
            ),
          ],

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirm(context),
          ),
        ],
      ),

      // ✅ FAB ONLY in non-edit mode
      floatingActionButton: _isEditMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                _hideSnackBar(); // ✅ kill snackbar

                Navigator.pushNamed(context, AppRoutes.services).then((_) {
                  if (!mounted) return;
                  _loadDevices(); // 🔥 refresh when coming back
                });
              },
              child: const Icon(Icons.add),
            ),

      body: Padding(
        padding: EdgeInsets.only(
          left: Responsive.pad(context),
          right: Responsive.pad(context),
          bottom: Responsive.pad(context),
          top: 0, // 👈 tiny controlled space
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔥 HEADER aligned with logo
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Saved Devices",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Welcome, $_welcomeName",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _loadingDevices
                  ? const Center(child: CircularProgressIndicator())
                  : devices.isEmpty
                  ? _emptyState(context)
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final d = devices[index];

                        final storedDeviceId = d.deviceId;
                        final deviceId = _normalizeDeviceId(storedDeviceId);
                        final deviceName =
                            d.displayName; // ✅ from register screen
                        final dept = d.department; // ✅ from register screen
                        final equipmentType = d.serviceType;

                        final status = _getSystemStatusForDevice(deviceId);

                        final selected = _selected.contains(storedDeviceId);

                        final liveTemp = _getTempForDevice(deviceId);
                        final telemetry = _telemetryByDevice[deviceId];
                        final isLoadingThisDevice = _loadingTempDeviceIds
                            .contains(deviceId);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              if (_isEditMode) {
                                _toggleSelection(storedDeviceId);
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
                                        onChanged: (_) =>
                                            _toggleSelection(storedDeviceId),
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
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
                                                  deviceId,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleMedium,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (!_isEditMode)
                                                _StatusChip(status: status),

                                              if (!_isEditMode) ...[
                                                const SizedBox(width: 6),

                                                IconButton(
                                                  icon: const Icon(
                                                    Icons
                                                        .notifications_active_outlined,
                                                  ),
                                                  tooltip:
                                                      "Notification settings",
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      AppRoutes
                                                          .notificationSettings,
                                                      arguments: {
                                                        "deviceId": deviceId,
                                                        "equipmentType":
                                                            equipmentType,
                                                      },
                                                    );
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "$deviceName • $dept",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),

                                              const SizedBox(height: 4),

                                              Text(
                                                equipmentType.replaceAll(
                                                  "_",
                                                  " ",
                                                ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              // ✅ ONLY REQUIRED ADDITION: TEMP LINE
                                              const SizedBox(height: 6),
                                              Text(
                                                (isLoadingThisDevice &&
                                                        telemetry == null)
                                                    ? "Temp: loading..."
                                                    : telemetry == null
                                                    ? "No data available"
                                                    : "Temp: ${liveTemp!} °C",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: telemetry == null
                                                          ? Theme.of(
                                                              context,
                                                            ).disabledColor
                                                          : Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),

                                              if (telemetry != null)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isDeviceOnline(deviceId)
                                                        ? Colors.green
                                                              .withValues(
                                                                alpha: 0.15,
                                                              )
                                                        : Colors.red.withValues(
                                                            alpha: 0.15,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          isDeviceOnline(
                                                            deviceId,
                                                          )
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.circle,
                                                        size: 7,
                                                        color:
                                                            isDeviceOnline(
                                                              deviceId,
                                                            )
                                                            ? Colors.green
                                                            : Colors.red,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isDeviceOnline(deviceId)
                                                            ? "Online"
                                                            : "Offline",
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              isDeviceOnline(
                                                                deviceId,
                                                              )
                                                              ? Colors.green
                                                              : Colors.red,
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
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
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: c),
      ),
    );
  }
}
