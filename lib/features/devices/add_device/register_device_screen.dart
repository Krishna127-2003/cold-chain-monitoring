
import 'package:flutter/material.dart';

import '../../../data/api/device_management_api.dart';
import '../../../data/session/session_manager.dart';
import '../../../routes/app_routes.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/loading_overlay.dart';

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

  void _show(String msg) {
    AppToast.show(msg);
  }


  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args =
        rawArgs is Map<String, dynamic> ? rawArgs : const <String, dynamic>{};

    final String deviceId = (args['deviceId'] ?? 'UNKNOWN').toString();
    final String equipmentType =
        (args['equipmentType'] ?? 'UNKNOWN').toString();
    final String productKey = (args['productKey'] ?? 'UNKNOWN').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Register Device')),
      body: LoadingOverlay(
        loading: _loading,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Registering Device: $deviceId',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Service: ${equipmentType.replaceAll('_', ' ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Device Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _deptController,
              decoration: const InputDecoration(
                labelText: 'Department (e.g., ICU / Blood Bank)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Area / Room (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Set 4-digit PIN',
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
                        final pin = _pinController.text.trim();
                        final pinValid = RegExp(r'^\d{4}$').hasMatch(pin);

                        if (_nameController.text.trim().isEmpty ||
                            _deptController.text.trim().isEmpty ||
                            !pinValid) {
                          AppToast.show("PIN must be exactly 4 digits");
                          return;
                        }

                        setState(() => _loading = true);

                        try {
                          final nav = Navigator.of(context); // capture before async use

                          final email = await SessionManager.getEmail();
                          if (email == null || email.isEmpty) {
                            throw Exception('Email missing');
                          }


                          final result = await DeviceManagementApi.registerDevice(
                            email: email,
                            deviceId: deviceId,

                            deviceProductKey: productKey,
                            deviceName: deviceId,

                            deviceDisplayName:
                                _nameController.text.trim(),
                            deviceDeptName:
                                _deptController.text.trim(),
                            deviceAreaRoom: _areaController.text.trim(),

                            devicePin: pin,
                            deviceType: equipmentType,

                          );

                          if (!mounted) return;

                          if (!result.success) {
                            _show(result.message);
                            return;
                          }

                          if (!mounted) return;
                          nav.popUntil(
                            (route) => route.settings.name == AppRoutes.allDevices,
                          );

                        } catch (_) {
                          if (!mounted) return;
                          AppToast.show("Device registration failed");
                        } finally {
                          if (mounted) {
                            setState(() => _loading = false);
                          }
                        }
                      },
                child: Text(
                  _loading ? 'Registering...' : 'Register Device',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
