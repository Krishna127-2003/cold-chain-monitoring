// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/responsive.dart';
import '../../routes/app_routes.dart';
import '../../data/storage/local_device_store.dart';
import 'widgets/status_badge.dart';

class DevicesListScreen extends StatefulWidget {
  final String equipmentType;

  const DevicesListScreen({super.key, required this.equipmentType});

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  bool _isEditMode = false;

  /// deviceIds selected
  final Set<String> _selected = {};

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
        final id = d["deviceId"] ?? "";
        if (id.toString().isNotEmpty) _selected.add(id.toString());
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selected.clear();
    });
  }

  Future<bool> _confirmDelete(BuildContext context, int count) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete device(s)?"),
        content: Text(
          "You are about to delete $count device(s) from Saved Devices.\n\nThis cannot be undone unless you press Undo immediately.",
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

  /// ✅ PIN verification popup (REQUIRED)
  Future<bool> _verifyPin(String correctPin) async {
    final pinController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter PIN to Delete"),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: "Enter device PIN",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final entered = pinController.text.trim();
              Navigator.pop(context, entered == correctPin.trim());
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    return ok ?? false;
  }

  /// ✅ SINGLE delete (PIN protected)
  Future<void> _deleteSingleDevice(
    List<Map<String, dynamic>> currentDevices,
    String deviceId,
  ) async {
    final okDelete = await _confirmDelete(context, 1);
    if (!okDelete) return;

    final device = currentDevices.firstWhere(
      (d) => (d["deviceId"] ?? "").toString() == deviceId,
      orElse: () => {},
    );

    final correctPin = (device["pin"] ?? "").toString();
    if (correctPin.isNotEmpty) {
      final okPin = await _verifyPin(correctPin);
      if (!okPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wrong PIN ❌ Delete cancelled")),
        );
        return;
      }
    }

    final deletedBackup = currentDevices
        .where((d) => (d["deviceId"] ?? "").toString() == deviceId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    await LocalDeviceStore.deleteDevice(
      equipmentType: widget.equipmentType,
      deviceId: deviceId,
    );

    setState(() {});

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("1 device deleted ✅"),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () async {
            for (final d in deletedBackup) {
              await LocalDeviceStore.addDevice(d);
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  /// ✅ MULTI delete (PIN protected)
  void _deleteSelectedDevices(
    List<Map<String, dynamic>> currentDevices,
  ) async {
    if (_selected.isEmpty) return;

    final okDelete = await _confirmDelete(context, _selected.length);
    if (!okDelete) return;

    // ✅ Backup deleted devices for Undo
    final deletedBackup = currentDevices
        .where((d) => _selected.contains((d["deviceId"] ?? "").toString()))
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // ✅ PIN check (IF ANY selected device has pin, ask pin for each device)
    for (final d in deletedBackup) {
      final correctPin = (d["pin"] ?? "").toString();
      if (correctPin.isNotEmpty) {
        final okPin = await _verifyPin(correctPin);
        if (!okPin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Wrong PIN ❌ Delete cancelled")),
          );
          return;
        }
      }
    }

    // ✅ Delete permanently
    await LocalDeviceStore.deleteMany(
      equipmentType: widget.equipmentType,
      deviceIds: _selected.toList(),
    );

    // ✅ Exit edit mode + refresh
    setState(() {
      _isEditMode = false;
      _selected.clear();
    });

    setState(() {});

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${deletedBackup.length} device(s) deleted ✅"),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () async {
            for (final d in deletedBackup) {
              await LocalDeviceStore.addDevice(d);
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pad(context);
    final equipmentType = widget.equipmentType;

    final devices = LocalDeviceStore.getDevices(equipmentType: equipmentType);

    return Scaffold(
      appBar: AppBar(
        title: _isEditMode
            ? Text("${_selected.length} selected")
            : const Text("Saved Devices"),
        actions: [
          if (devices.isNotEmpty)
            IconButton(
              icon: Icon(_isEditMode ? Icons.close : Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: _isEditMode ? "Exit edit mode" : "Edit devices",
            ),

          if (_isEditMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () => _selectAll(devices),
              tooltip: "Select All",
            ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearSelection,
              tooltip: "Clear selection",
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selected.isEmpty
                  ? null
                  : () => _deleteSelectedDevices(devices),
              tooltip: "Delete selected",
            ),
          ],
        ],
      ),

      floatingActionButton: _isEditMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.qrScan,
                  arguments: {"equipmentType": equipmentType},
                );
              },
              child: const Icon(Icons.add),
            ),

      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              equipmentType.replaceAll("_", " "),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              _isEditMode
                  ? "Select devices and delete safely"
                  : "Manage and monitor devices in this category",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: devices.isEmpty
                  ? _EmptyState(
                      equipmentType: equipmentType,
                      icon: _iconForType(equipmentType),
                    )
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final d = devices[index];

                        final deviceId = (d["deviceId"] ?? "-").toString();
                        final deviceName =
                            (d["deviceName"] ?? "Unnamed Device").toString();
                        final dept = (d["department"] ?? "-").toString();
                        final status = (d["status"] ?? "NORMAL").toString();

                        final lastUpdated = DateTime.tryParse(
                          (d["lastUpdated"] ?? "").toString(),
                        );
                        final formatted = lastUpdated == null
                            ? "-"
                            : DateFormat("dd MMM, hh:mm a").format(lastUpdated);

                        final selected = _selected.contains(deviceId);

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
                                        onChanged: (_) =>
                                            _toggleSelection(deviceId),
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
                                                  deviceName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),

                                              // ✅ SINGLE DELETE ICON (EDIT MODE ONLY)
                                              if (_isEditMode)
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      _deleteSingleDevice(
                                                    devices,
                                                    deviceId,
                                                  ),
                                                ),

                                              if (!_isEditMode)
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: StatusBadge(
                                                    status: status,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "$dept • $deviceId",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "Last Updated: $formatted",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      const Color(0xFF64748B),
                                                  fontSize: 12.5,
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
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String equipmentType;
  final IconData icon;

  const _EmptyState({
    required this.equipmentType,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
                  icon,
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
                "Tap + to add your first device in this category.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
