import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';


class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {

  final _controller = TextEditingController();
  bool _loading = false;

Future<void> _continue() async {
  final value = _controller.text.trim();
  if (value.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter device code")),
    );
    return;
  }/*  */
  
  setState(() => _loading = true);
    try {
      await Navigator.pushNamed(
        context,
        AppRoutes.productKey,
        arguments: {
          "deviceId": value,
          "equipmentType": (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>)["equipmentType"],
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final equipmentType = args?["equipmentType"] ?? "UNKNOWN";

    return Scaffold(
      appBar: AppBar(title: const Text("Enter Device Code")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Enter ${equipmentType.replaceAll("_", " ")} device code",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Device ID / QR Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _continue,
              child: const Text("Continue"),
            )
          ],
        ),
      ),
    );
  }
}

