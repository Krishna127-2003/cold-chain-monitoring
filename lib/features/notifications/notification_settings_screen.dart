import 'package:flutter/material.dart';
import 'alert_settings_storage.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool appAlert = true;
  bool emailAlert = true;
  bool smsAlert = true;
  int selectedLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await AlertSettingsStorage.load();
    if (!mounted) return;

    setState(() {
      appAlert = data["app"] ?? true;
      emailAlert = data["email"] ?? true;
      smsAlert = data["sms"] ?? true;
      selectedLevel = data["level"] ?? 1;
    });
  }

  // FIXED: Moved RadioGroup to wrap the entire list instead of inside a single item
  Widget levelOption(int level, String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<int>(
        value: level,
        // groupValue and onChanged are now handled by the parent RadioGroup
      ),
      title: Text(label),
      onTap: () => setState(() => selectedLevel = level),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notification Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Delivery Channels",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              value: appAlert,
              title: const Text("App"),
              onChanged: (v) => setState(() => appAlert = v ?? false),
            ),
            CheckboxListTile(
              value: emailAlert,
              title: const Text("Email"),
              onChanged: (v) => setState(() => emailAlert = v ?? false),
            ),
            CheckboxListTile(
              value: smsAlert,
              title: const Text("SMS"),
              onChanged: (v) => setState(() => smsAlert = v ?? false),
            ),
            const SizedBox(height: 20),
            const Text(
              "Alert Escalation Level",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            // FIXED: RadioGroup wraps the list of Radios
            RadioGroup<int>(
              groupValue: selectedLevel,
              onChanged: (v) {
                if (v != null) setState(() => selectedLevel = v);
              },
              child: Column(
                children: [
                  levelOption(5, "Level 5 — after 24 hours"),
                  levelOption(4, "Level 4 — after 12 hours"),
                  levelOption(3, "Level 3 — after 4 hours"),
                  levelOption(2, "Level 2 — after 2 hours"),
                  levelOption(1, "Level 1 — after 1 hour"),
                  levelOption(0, "Level 0 — instant"),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);

                    await AlertSettingsStorage.save(
                      app: appAlert,
                      email: emailAlert,
                      sms: smsAlert,
                      level: selectedLevel,
                    );

                    if (!mounted) return;

                    messenger.showSnackBar(
                      const SnackBar(content: Text("Settings saved")),
                    );
                  },
                child: const Text("Update Settings"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}