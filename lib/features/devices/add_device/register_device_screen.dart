// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../../data/models/registered_device.dart';
import '../../../data/repository/device_repository.dart';
import '../../../data/repository_impl/local_device_repository.dart';
import '../../../data/session/session_manager.dart';
import '../../../data/api/device_registration_api.dart';

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

            /// Device Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Device Display Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            /// Department
            TextField(
              controller: _deptController,
              decoration: const InputDecoration(
                labelText: "Department (e.g., ICU / Blood Bank)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            /// Area (optional)
            TextField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: "Area / Room (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            /// PIN
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

            /// REGISTER BUTTON
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

                        /// SESSION INFO
                        final loginType =
                            await SessionManager.getLoginType() ?? "guest";
                        final email =
                            await SessionManager.getEmail() ?? "guest";

                        final now = DateTime.now().toUtc();

                        /// ✅ LOCAL MODEL (SOURCE OF TRUTH)
                        final device = RegisteredDevice(
                          deviceId: deviceId,
                          qrCode: deviceId, // QR = deviceId for now
                          productKey: productKey,
                          serviceType: equipmentType,
                          email: email,
                          loginType: loginType,
                          registeredAt: now,
                        );

                        /// 1️⃣ SAVE LOCALLY (offline-safe)
                        await _deviceRepo.registerDevice(device);

                        /// 2️⃣ SEND REGISTRATION CALLBACK TO AZURE
                        await DeviceRegistrationApi.registerDevice(
                          email: email,
                          loginType: loginType,
                          deviceId: deviceId,
                          qrCode: deviceId,
                          productKey: productKey,
                          serviceType: equipmentType,
                          registeredAt: now,
                        );

                        setState(() => _loading = false);

                        /// 3️⃣ GO TO SAVED DEVICES
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
