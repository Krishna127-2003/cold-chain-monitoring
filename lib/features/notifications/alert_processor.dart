import 'alert_engine.dart';
import 'alert_settings_storage.dart';
import 'notification_service.dart';
import '../../core/utils/log_safe.dart';
import '../alerts_history/alert_history_storage.dart';
import 'state/alert_type.dart';
import 'state/alert_status.dart';
import 'state/alert_event.dart';

class AlertProcessor {
  final Map<String, AlertEngine> _engines = {};

  /// deviceId -> (alertType -> active event)
  final Map<String, Map<AlertType, AlertEvent>> _activeAlerts = {};

  AlertEngine _engineFor(String deviceId) {
    return _engines.putIfAbsent(deviceId, () => AlertEngine());
  }

  Future<void> process({
    required String deviceId,
    required String equipmentType,
    double? temperature,
    double? sv,
    int? batteryPercent,
    required bool powerFail,
    required bool probeFail,
    required bool systemError,
  }) async {

    
    final settings = await AlertSettingsStorage.load(
      deviceId: deviceId,
      equipmentType: equipmentType,
    );

    
    final engine = _engineFor(deviceId);

    final activeNow = engine.evaluate(
      pv: temperature,
      sv: sv,
      equipmentType: equipmentType,
      batteryPercent: batteryPercent,
      powerFail: powerFail,
      probeFail: probeFail,
      systemError: systemError,
      settings: settings,
    );

    final deviceAlerts =
        _activeAlerts.putIfAbsent(deviceId, () => {});

    final now = DateTime.now();
    logSafe("ACTIVE NOW $deviceId → $activeNow");
    // ================= OPEN NEW ALERTS =================
    for (final type in activeNow) {
      if (deviceAlerts.containsKey(type)) continue;

      final event = AlertEvent(
        deviceId: deviceId,
        type: type,
        status: AlertStatus.open,
        openedAt: now,
        
      );

      deviceAlerts[type] = event;

      logSafe("🚨 OPEN → $type ($deviceId)");

      await NotificationService.send(
        "$equipmentType Alert",
        "$deviceId • ${_buildMessage(type, temperature, batteryPercent)}",
      );
      _storeEvent(event);
    }

    // ================= RESOLVE CLEARED ALERTS =================
    final previouslyActive =
        List<AlertType>.from(deviceAlerts.keys);

    for (final type in previouslyActive) {
      if (activeNow.contains(type)) continue;

      final event = deviceAlerts[type]!;
      event.status = AlertStatus.resolved;
      event.resolvedAt = now;

      logSafe("✅ RESOLVED → $type ($deviceId)");

      deviceAlerts.remove(type);

      _storeEvent(event);
    }
  }

  // --------------------------------------------------

  String _buildMessage(
    AlertType type,
    double? temp,
    int? battery,
  ) {
    switch (type) {
      case AlertType.powerFail:
        return "Power failure detected";

      case AlertType.probeFail:
        return "Temperature probe failure";

      case AlertType.systemError:
        return "System error detected";

      case AlertType.batteryLow:
        return "Battery low: ${battery ?? '--'}%";

      case AlertType.highTemp:
        return "High temperature: ${temp?.toStringAsFixed(1) ?? '--'}°C";

      case AlertType.lowTemp:
        return "Low temperature: ${temp?.toStringAsFixed(1) ?? '--'}°C";
    }
  }

  // --------------------------------------------------
  // (Next step will persist into history storage)

  Future<void> _storeEvent(AlertEvent event) async {
    if (event.status == AlertStatus.open) {
      await AlertHistoryStorage.append(event);
    } else {
      await AlertHistoryStorage.replace(event);
    }

    logSafe(
      "HISTORY SAVED → ${event.deviceId} | ${event.type} | ${event.status}",
    );
  }

  // Optional safety resets (good for logout / reload)

  void resetDevice(String deviceId) {
    _activeAlerts.remove(deviceId);
    _engines[deviceId]?.reset();
  }

  void resetAll() {
    _activeAlerts.clear();
    for (final e in _engines.values) {
      e.reset();
    }
  }

  AlertProcessor() {
    _restore();
  }

  Future<void> _restore() async {
    final restored = await AlertHistoryStorage.loadActive();
    _activeAlerts.addAll(restored);
  }
}