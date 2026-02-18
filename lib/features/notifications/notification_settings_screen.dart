import 'package:flutter/material.dart';
import 'alert_settings.dart';
import 'alert_settings_storage.dart';
import 'equipment_standards.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {

  String _deviceId = "global";
  bool _initialized = false;

  late AlertSettings _settings;
  late TempLimits _limits;
  late String _equipmentType;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    _deviceId = (args?["deviceId"] ?? "global").toString().trim();
    if (_deviceId.isEmpty) _deviceId = "global";

    _equipmentType = (args?["equipmentType"] ?? "").toString();

    _limits = EquipmentStandards.limitsFor(_equipmentType);

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final loaded = await AlertSettingsStorage.load(
      deviceId: _deviceId,
      equipmentType: _equipmentType,
    );

    if (!mounted) return;

    setState(() {
      _settings = loaded;
    });
  }

  Future<void> _save() async {
    await AlertSettingsStorage.save(
      settings: _settings,
      deviceId: _deviceId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Alert settings updated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Alert Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= TEMPERATURE =================
            const Text(
              "Temperature Alerts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text("Enable High Temperature Alert"),
              value: _settings.highTempEnabled,
              onChanged: (v) => setState(() => _settings.highTempEnabled = v),
            ),

            Text("High Temp Threshold: ${_settings.highTempThreshold.toStringAsFixed(1)}°C"),
            Slider(
              min: _limits.min,
              max: _limits.max + 10, // little buffer
              divisions: 60,
              value: _settings.highTempThreshold,
              onChanged: (v) =>
                  setState(() => _settings.highTempThreshold = v),
            ),

            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text("Enable Low Temperature Alert"),
              value: _settings.lowTempEnabled,
              onChanged: (v) => setState(() => _settings.lowTempEnabled = v),
            ),

            Text("Low Temp Threshold: ${_settings.lowTempThreshold.toStringAsFixed(1)}°C"),
            Slider(
              min: _limits.min - 10,
              max: _limits.max,
              divisions: 60,
              value: _settings.lowTempThreshold,
              onChanged: (v) =>
                  setState(() => _settings.lowTempThreshold = v),
            ),

            const SizedBox(height: 24),

            // ================= BATTERY =================
            const Text(
              "Battery Alert",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text("Enable Battery Alert"),
              value: _settings.batteryEnabled,
              onChanged: (v) => setState(() => _settings.batteryEnabled = v),
            ),

            Text("Alert Below: ${_settings.batteryBelowPercent}%"),
            Slider(
              min: 5,
              max: 50,
              divisions: 45,
              value: _settings.batteryBelowPercent.toDouble(),
              onChanged: (v) =>
                  setState(() => _settings.batteryBelowPercent = v.round()),
            ),

            const SizedBox(height: 24),

            // ================= FAILURES =================
            const Text(
              "System Failures",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text("Power Failure"),
              value: _settings.powerFailEnabled,
              onChanged: (v) => setState(() => _settings.powerFailEnabled = v),
            ),

            SwitchListTile(
              title: const Text("Probe Failure"),
              value: _settings.probeFailEnabled,
              onChanged: (v) => setState(() => _settings.probeFailEnabled = v),
            ),

            SwitchListTile(
              title: const Text("System Error"),
              value: _settings.systemErrorEnabled,
              onChanged: (v) => setState(() => _settings.systemErrorEnabled = v),
            ),

            const SizedBox(height: 24),

            // ================= DELAY =================
            const Text(
              "Trigger Delay",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Text("Delay: ${_settings.triggerDelay.inMinutes} minutes"),
            Slider(
              min: 0,
              max: 60,
              divisions: 12,
              value: _settings.triggerDelay.inMinutes.toDouble(),
              onChanged: (v) => setState(() =>
                  _settings.triggerDelay = Duration(minutes: v.round())),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text(
                  "Save Settings",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
