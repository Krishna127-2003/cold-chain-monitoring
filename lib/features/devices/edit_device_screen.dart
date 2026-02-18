import 'package:flutter/material.dart';
import '../../data/models/registered_device.dart';
import '../../data/api/device_management_api.dart';
import '../../data/session/session_manager.dart';
import '../../core/ui/app_toast.dart';
import '../../core/ui/loading_overlay.dart';

class EditDeviceScreen extends StatefulWidget {
  const EditDeviceScreen({super.key});

  @override
  State<EditDeviceScreen> createState() => _EditDeviceScreenState();
}

class _EditDeviceScreenState extends State<EditDeviceScreen> {
  late RegisteredDevice device;

  late TextEditingController nameCtrl;
  late TextEditingController deptCtrl;
  late TextEditingController areaCtrl;
  late TextEditingController typeCtrl;
  final pinCtrl = TextEditingController();

  bool _saving = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      device = ModalRoute.of(context)!.settings.arguments as RegisteredDevice;

      nameCtrl = TextEditingController(text: device.displayName);
      deptCtrl = TextEditingController(text: device.department);
      areaCtrl = TextEditingController(text: device.area);
      typeCtrl = TextEditingController(text: device.serviceType);

      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    deptCtrl.dispose();
    areaCtrl.dispose();
    typeCtrl.dispose();
    pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Device")),
      body: LoadingOverlay(
        loading: _saving,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field("Display Name", nameCtrl),
            _field("Department", deptCtrl),
            _field("Area / Room", areaCtrl),
            _field("Device Type", typeCtrl),

            const SizedBox(height: 16),

            TextField(
              controller: pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter PIN to Save",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _updateDevice,
                child: Text(_saving ? "Saving..." : "Update Device"),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _updateDevice() async {
    final pin = pinCtrl.text.trim();

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      _msg("PIN must be exactly 4 digits");
      return;
    }

    setState(() => _saving = true);

    try {
      final email = await SessionManager.getEmail();
      if (email == null || email.isEmpty) throw Exception();

      final result = await DeviceManagementApi.updateDevice(
        email: email,
        deviceId: device.deviceId,
        devicePin: pin,

        deviceDisplayName:
            nameCtrl.text.trim() != device.displayName
                ? nameCtrl.text.trim()
                : null,

        deviceDeptName:
            deptCtrl.text.trim() != device.department
                ? deptCtrl.text.trim()
                : null,

        deviceAreaRoom:
            areaCtrl.text.trim() != device.area
                ? areaCtrl.text.trim()
                : null,

        deviceType:
            typeCtrl.text.trim() != device.serviceType
                ? typeCtrl.text.trim()
                : null,
      );

      if (!result.success) {
        _msg(result.message);
        return;
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _msg("Update failed — check PIN or network");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _msg(String s) {
    AppToast.show(s);
  }

}
