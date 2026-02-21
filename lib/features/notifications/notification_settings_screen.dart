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

  AlertSettings? _settings;
  late TempLimits _limits;
  late String _equipmentType;

  bool _saving = false;
  bool _saved = false; // ✅ success indicator

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

    setState(() => _settings = loaded);
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _saved = false;
    });

    await AlertSettingsStorage.save(
      settings: _settings!,
      deviceId: _deviceId,
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
      _saved = true;
    });

    // show ✓ Saved for 1 second
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {

    if (!_initialized || _settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final settings = _settings!;

    return Scaffold(
      appBar: AppBar(title: const Text("Alert Settings")),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Temperature Alerts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text("Enable High Temperature Alert"),
                value: settings.highTempEnabled,
                onChanged: (v) =>
                    setState(() => settings.highTempEnabled = v),
              ),

              Text(
                "High Temp Threshold: ${settings.highTempThreshold.toStringAsFixed(1)}°C",
              ),
              Slider(
                min: _limits.min,
                max: _limits.max + 10,
                divisions: 60,
                value: settings.highTempThreshold,
                onChanged: (v) =>
                    setState(() => settings.highTempThreshold = v),
              ),

              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text("Enable Low Temperature Alert"),
                value: settings.lowTempEnabled,
                onChanged: (v) =>
                    setState(() => settings.lowTempEnabled = v),
              ),

              Text(
                "Low Temp Threshold: ${settings.lowTempThreshold.toStringAsFixed(1)}°C",
              ),
              Slider(
                min: _limits.min - 10,
                max: _limits.max,
                divisions: 60,
                value: settings.lowTempThreshold,
                onChanged: (v) =>
                    setState(() => settings.lowTempThreshold = v),
              ),

              const SizedBox(height: 24),

              const Text(
                "Battery Alert",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text("Enable Battery Alert"),
                value: settings.batteryEnabled,
                onChanged: (v) =>
                    setState(() => settings.batteryEnabled = v),
              ),

              Text("Alert Below: ${settings.batteryBelowPercent}%"),
              Slider(
                min: 5,
                max: 50,
                divisions: 45,
                value: settings.batteryBelowPercent.toDouble(),
                onChanged: (v) =>
                    setState(() => settings.batteryBelowPercent = v.round()),
              ),

              const SizedBox(height: 24),

              const Text(
                "System Failures",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text("Power Failure"),
                value: settings.powerFailEnabled,
                onChanged: (v) =>
                    setState(() => settings.powerFailEnabled = v),
              ),

              SwitchListTile(
                title: const Text("Probe Failure"),
                value: settings.probeFailEnabled,
                onChanged: (v) =>
                    setState(() => settings.probeFailEnabled = v),
              ),

              SwitchListTile(
                title: const Text("System Error"),
                value: settings.systemErrorEnabled,
                onChanged: (v) =>
                    setState(() => settings.systemErrorEnabled = v),
              ),

              const SizedBox(height: 24),

              const Text(
                "Trigger Delay",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Text("Delay: ${settings.triggerDelay.inMinutes} minutes"),
              Slider(
                min: 0,
                max: 60,
                divisions: 12,
                value: settings.triggerDelay.inMinutes.toDouble(),
                onChanged: (v) => setState(() =>
                    settings.triggerDelay =
                        Duration(minutes: v.round())),
              ),

              const SizedBox(height: 30),

              // ================= SAVE BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed:
                      (_saving || _saved) ? null : _save,

                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _saved
                          ? const Icon(Icons.check_circle,
                              color: Colors.green)
                          : const Icon(Icons.save),

                  label: Text(
                    _saving
                        ? "Saving..."
                        : _saved
                            ? "Saved"
                            : "Save Settings",
                    style: const TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
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