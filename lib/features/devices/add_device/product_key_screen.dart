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
    required String productKey,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.registerDevice,
      arguments: {
        'deviceId': deviceId,
        'equipmentType': equipmentType,
        'productKey': productKey,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args =
        rawArgs is Map<String, dynamic> ? rawArgs : const <String, dynamic>{};

    final deviceId = (args['deviceId'] ?? 'UNKNOWN').toString();
    final equipmentType = (args['equipmentType'] ?? 'UNKNOWN').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Product Key')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Device ID: $deviceId',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _keyController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Product Key',
                hintText: 'XXXX-XXXX',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        final key = _keyController.text.trim();

                        if (key.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter product key'),
                            ),
                          );
                          return;
                        }

                        setState(() => _loading = true);

                        try {
                          // MOCK verification (replace with backend call later)
                          await Future.delayed(
                            const Duration(milliseconds: 700),
                          );

                          if (!mounted) return;
                          _goNext(
                            deviceId: deviceId,
                            equipmentType: equipmentType,
                            productKey: key,
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product key verification failed'),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _loading = false);
                          }
                        }
                      },
                child: Text(_loading ? 'Verifying...' : 'Verify Product Key'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bolt),
                label: const Text(
                  'Product Key Required',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                onPressed: null,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'A valid product key is required to continue.',
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
