import 'dart:convert';
import 'package:marken_iot/core/utils/log_safe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notifications/state/alert_event.dart';
import '../notifications/state/alert_type.dart';    
import '../notifications/state/alert_status.dart';

class AlertHistoryStorage {
  static const _key = "alert_history";

  static Future<List<AlertEvent>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null) return [];

    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => AlertEvent.fromJson(e)).toList();
  }

  static Future<Map<String, Map<AlertType, AlertEvent>>> loadActive() async {
    final list = await load();

    final Map<String, Map<AlertType, AlertEvent>> active = {};

    for (final e in list) {
      if (e.status != AlertStatus.open) continue;

      active.putIfAbsent(e.deviceId, () => {});
      active[e.deviceId]![e.type] = e;
    }

    return active;
  }

  static Future<void> append(AlertEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await load();

    existing.insert(0, event); // newest first

    final encoded = jsonEncode(
      existing.map((e) => e.toJson()).toList(),
    );

    await prefs.setString(_key, encoded);

    logSafe("HISTORY APPEND → ${event.type} for ${event.deviceId}");

  }

  static Future<void> replace(AlertEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load();

    final index = list.indexWhere(
      (e) =>
        e.deviceId == event.deviceId &&
        e.type == event.type &&
        e.openedAt == event.openedAt,
    );

    if (index != -1) list[index] = event;

    final encoded = jsonEncode(
      list.map((e) => e.toJson()).toList(),
    );

    await prefs.setString(_key, encoded);

    logSafe("HISTORY RESOLVE → ${event.type} for ${event.deviceId}");

  }

  static Future<void> delete(AlertEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load();

    list.removeWhere((e) =>
        e.deviceId == event.deviceId &&
        e.type == event.type &&
        e.openedAt == event.openedAt);

    await prefs.setString(
      _key,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );

    logSafe("HISTORY DELETE → ${event.type} ${event.deviceId}");
  }
}