import 'package:flutter/material.dart';
import 'package:marken_iot/core/utils/log_safe.dart';
import 'alert_history_storage.dart';
import '../notifications/state/alert_event.dart';
import '../notifications/state/alert_status.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  List<AlertEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AlertHistoryStorage.load();
    setState(() => _events = list);
    logSafe("HISTORY LOADED → ${list.length} events");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alerts")),
      body: _events.isEmpty
          ? const Center(child: Text("No alerts yet"))
          : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (_, i) {
                final e = _events[i];

                return Dismissible(
                  key: ValueKey("${e.deviceId}-${e.openedAt}"),
                  direction: e.status == AlertStatus.resolved
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
                  onDismissed: (_) async {
                    await AlertHistoryStorage.delete(e);
                    _load();
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: Icon(
                      e.status == AlertStatus.open
                          ? Icons.warning
                          : Icons.check_circle,
                      color: e.status == AlertStatus.open
                          ? Colors.red
                          : Colors.green,
                    ),
                    title: Text("${e.deviceId} — ${e.type.name}"),
                    subtitle: Text(
                      e.status == AlertStatus.open
                          ? "Active since ${e.openedAt}"
                          : "Resolved at ${e.resolvedAt}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}