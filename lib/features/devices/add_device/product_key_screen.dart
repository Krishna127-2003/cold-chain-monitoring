// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

class ProductKeyScreen extends StatefulWidget {
  const ProductKeyScreen({super.key});

  @override
  State<ProductKeyScreen> createState() => _ProductKeyScreenState();
}

class _ProductKeyScreenState extends State<ProductKeyScreen> {
  final TextEditingController _keyController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _goNext({
    required String deviceId,
    required String equipmentType,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.registerDevice,
      arguments: {
        "deviceId": deviceId,
        "equipmentType": equipmentType,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final deviceId = (args?["deviceId"] ?? "UNKNOWN").toString();
    final equipmentType = (args?["equipmentType"] ?? "UNKNOWN").toString();

    return Scaffold(
      appBar: AppBar(title: const Text("Enter Product Key")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Device ID: $deviceId",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: "Product Key",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            /// ✅ Normal Verify Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (_keyController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Enter product key"),
                            ),
                          );
                          return;
                        }

                        setState(() => _loading = true);

                        // ✅ For now mock verify (later connect to Azure verify API)
                        await Future.delayed(const Duration(milliseconds: 700));

                        setState(() => _loading = false);

                        _goNext(
                          deviceId: deviceId,
                          equipmentType: equipmentType,
                        );
                      },
                child: Text(_loading ? "Verifying..." : "Verify Product Key"),
              ),
            ),

            const SizedBox(height: 12),

            /// ✅ NEW: Skip Product Key button (Only for testing demo)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bolt),
                label: const Text(
                  "Skip Product Key (Demo)",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                onPressed: () {
                  _goNext(
                    deviceId: deviceId,
                    equipmentType: equipmentType,
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Demo mode allows direct registration without product key.\nLater we will connect product key verification to backend.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
