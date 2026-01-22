// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../routes/app_routes.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final equipmentType = args?["equipmentType"] ?? "UNKNOWN";

    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                if (_scanned) return;

                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;

                final rawValue = barcodes.first.rawValue;
                if (rawValue == null || rawValue.isEmpty) return;

                setState(() => _scanned = true);

                // For now we assume rawValue is the deviceId
                // Example: "DF-001"
                Navigator.pushNamed(
                  context,
                  AppRoutes.productKey,
                  arguments: {
                    "deviceId": rawValue,
                    "equipmentType": equipmentType,
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _scanned
                  ? "QR scanned! Redirecting..."
                  : "Point the camera at the device QR code.",
            ),
          ),
        ],
      ),
    );
  }
}
