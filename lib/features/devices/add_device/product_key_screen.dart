// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/mock_device_service.dart';

class ProductKeyScreen extends StatefulWidget {
  const ProductKeyScreen({super.key});

  @override
  State<ProductKeyScreen> createState() => _ProductKeyScreenState();
}

class _ProductKeyScreenState extends State<ProductKeyScreen> {
  final TextEditingController _keyController = TextEditingController();
  final MockDeviceService _mockDeviceService = MockDeviceService();

  bool _loading = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final deviceId = args?["deviceId"] ?? "UNKNOWN";
    final equipmentType = args?["equipmentType"] ?? "UNKNOWN";

    return Scaffold(
      appBar: AppBar(title: const Text("Enter Product Key")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Device ID: $deviceId",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: "Product Key",
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
                        final key = _keyController.text.trim();
                        if (key.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Enter product key")),
                          );
                          return;
                        }

                        setState(() => _loading = true);

                        final result = await _mockDeviceService.verifyDevice(
                          deviceId: deviceId,
                          productKey: key,
                          equipmentType: equipmentType,
                        );

                        setState(() => _loading = false);

                        final verified = result["verified"] == true;

                        if (!verified) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result["message"] ?? "Verification failed",
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.pushNamed(
                          context,
                          AppRoutes.registerDevice,
                          arguments: {
                            "deviceId": deviceId,
                            "equipmentType": equipmentType,
                            "productKey": key,
                          },
                        );
                      },
                child: Text(_loading ? "Verifying..." : "Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
