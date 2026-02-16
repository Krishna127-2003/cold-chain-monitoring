import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../dashboard/utils/device_id_helper.dart';class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final rawInput = _controller.text;

    final deviceId = DeviceIdHelper.normalize(rawInput);

    if (deviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid device code')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await Navigator.pushNamed(
        context,
        AppRoutes.productKey,
        arguments: {
          'deviceId': deviceId,
          'equipmentType':
              (ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?)?['equipmentType'] ??
                  'UNKNOWN',
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final equipmentType = args?['equipmentType'] ?? 'UNKNOWN';

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Device Code')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Enter ${equipmentType.replaceAll('_', ' ')} device code',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Device ID / QR Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _continue,
              child: const Text('Continue'),
            )
          ],
        ),
      ),
    );
  }
}