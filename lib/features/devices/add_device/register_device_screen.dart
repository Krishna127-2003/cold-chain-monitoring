// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../../data/models/registered_device.dart';
import '../../../data/repository/device_repository.dart';
import '../../../data/repository_impl/local_device_repository.dart';
import '../../../data/session/session_manager.dart';
import '../../../data/api/device_callback_api.dart';

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

  final DeviceRepository _deviceRepo = LocalDeviceRepository();

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

    final String deviceId = args?["deviceId"] ?? "UNKNOWN";
    final String equipmentType = args?["equipmentType"] ?? "UNKNOWN";
    final String productKey = args?["productKey"] ?? "UNKNOWN";

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
            const SizedBox(height: 8),
            Text(
              "Service: ${equipmentType.replaceAll('_', ' ')}",
              style: TextStyle(color: Colors.grey.shade600),
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
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (_nameController.text.trim().isEmpty ||
                            _deptController.text.trim().isEmpty ||
                            _pinController.text.trim().length < 4) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Fill required fields correctly"),
                            ),
                          );
                          return;
                        }

                        setState(() => _loading = true);

                        final loginType =
                            await SessionManager.getLoginType() ?? "guest";

                        final email =
                            await SessionManager.getEmail() ?? "guest";

                        /// ✅ FINAL & CORRECT MODEL USAGE
                        final device = RegisteredDevice(
                          deviceId: deviceId,
                          qrCode: deviceId, // QR = device id for now
                          productKey: productKey,
                          serviceType: equipmentType,
                          email: email,
                          loginType: loginType,
                          registeredAt: DateTime.now().toUtc(),
                        );

                        await _deviceRepo.registerDevice(device);

                        /// 🔔 CALLBACK (Vinay – POC)
                        await DeviceCallbackApi.sendDeviceData(
                          deviceId: deviceId,
                          temperature: -18,
                          humidity: 42.5,
                          compressor: 1,
                          defrost: 0,
                          door: 0,
                          power: 1,
                          battery: 85,
                        );

                        setState(() => _loading = false);

                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.allDevices,
                          (route) => false,
                        );
                      },
                child: Text(
                  _loading ? "Registering..." : "Register Device",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
