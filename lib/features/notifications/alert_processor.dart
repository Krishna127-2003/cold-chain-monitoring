// ignore_for_file: avoid_print

import 'alert_engine.dart';
import 'alert_settings_storage.dart';
import 'notification_service.dart';

class AlertProcessor {
  final Map<String, AlertEngine> _engines = {};
  final Map<String, DateTime> _lastSentAt = {};

  static const Duration _cooldown = Duration(minutes: 2);

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

    print("ALERT CHECK → temp=$temperature battery=$batteryPercent power=$powerFail probe=$probeFail system=$systemError");

    final shouldFire = engine.shouldTrigger(
      pv: temperature,
      sv: sv,
      equipmentType: equipmentType,
      batteryPercent: batteryPercent,
      powerFail: powerFail,
      probeFail: probeFail,
      systemError: systemError,
      settings: settings,
    );

    if (!shouldFire) return;

    final now = DateTime.now();
    final last = _lastSentAt[deviceId];

    if (last != null && now.difference(last) < _cooldown) return;

    _lastSentAt[deviceId] = now;

    print("🚨 ALERT FIRED FOR $deviceId");

    await NotificationService.sendRepeated(
      "Cold Chain Alert",
      _buildMessage(
        temperature,
        batteryPercent,
        powerFail,
        probeFail,
        systemError,
      ),
    );
  }

  String _buildMessage(
    double? temp,
    int? battery,
    bool power,
    bool probe,
    bool system,
  ) {
    if (power) return "Power failure detected";
    if (probe) return "Temperature probe failure";
    if (system) return "System error detected";

    if (battery != null && battery < 25) {
      return "Battery low: $battery% remaining";
    }

    if (temp != null) {
      return "Temperature out of safe range: ${temp.toStringAsFixed(1)}°C";
    }

    return "Cold chain alert triggered";
  }

  void resetDevice(String deviceId) {
    _engines[deviceId]?.reset();
    _lastSentAt.remove(deviceId);
  }

  void resetAll() {
    for (final engine in _engines.values) {
      engine.reset();
    }
    _lastSentAt.clear();
  }
}
