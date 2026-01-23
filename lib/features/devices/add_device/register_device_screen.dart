// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../../data/storage/local_device_store.dart';

class RegisterDeviceScreen extends StatefulWidget {
  const RegisterDeviceScreen({super.key});

  @override
  State<RegisterDeviceScreen> createState() => _RegisterDeviceScreenState();
}

class _RegisterDeviceScreenState extends State<RegisterDeviceScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _deptController.dispose();
    _areaController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final deviceId = args?["deviceId"] ?? "UNKNOWN";
    final equipmentType = args?["equipmentType"] ?? "UNKNOWN";

    return Scaffold(
      appBar: AppBar(title: const Text("Register Device")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Registering Device: $deviceId",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Device Display Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _deptController,
              decoration: const InputDecoration(
                labelText: "Department (e.g., ICU / Blood Bank)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: "Area / Room (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Set PIN (4 or 6 digits)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (_nameController.text.trim().isEmpty ||
                            _deptController.text.trim().isEmpty ||
                            _pinController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Fill required fields"),
                            ),
                          );
                          return;
                        }

                        setState(() => _loading = true);

                        // ✅ MVP now: mock register delay
                        await Future.delayed(const Duration(seconds: 1));

                        // ✅ Save device PERSISTENTLY (SharedPreferences)
                        await LocalDeviceStore.addDevice({
                          "deviceId": deviceId,
                          "deviceName": _nameController.text.trim(),
                          "equipmentType": equipmentType,
                          "department": _deptController.text.trim(),
                          "area": _areaController.text.trim(),
                          "pin": _pinController.text.trim(), // ✅ REQUIRED (PIN saved)
                          "status": "NORMAL",
                          "lastUpdated": DateTime.now().toIso8601String(),
                        });

                        setState(() => _loading = false);

                        // ✅ Navigate to dashboard
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.dashboard,
                          (route) => false,
                          arguments: {
                            "deviceId": deviceId,
                            "equipmentType": equipmentType,
                          },
                        );
                      },
                child: Text(_loading ? "Registering..." : "Register Device"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
