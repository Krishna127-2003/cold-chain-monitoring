import 'alert_settings.dart';
import 'state/alert_type.dart';
import '../../core/utils/log_safe.dart';

class AlertEngine {
  DateTime? _highTempStart;
  DateTime? _lowTempStart;
  DateTime? _batteryStart;

  List<AlertType> evaluate({
    required double? pv,
    required double? sv, // keep but ignore
    required String equipmentType,
    required int? batteryPercent,
    required bool powerFail,
    required bool probeFail,
    required bool systemError,
    required AlertSettings settings,
  }) {
    final now = DateTime.now();
    final List<AlertType> active = [];
    logSafe("ENGINE ACTIVE → $active");
    // ===== HIGH TEMP =====
    if (settings.highTempEnabled &&
        pv != null &&
        pv > settings.highTempThreshold) {

      _highTempStart ??= now;

      if (now.difference(_highTempStart!) >= settings.triggerDelay) {
        active.add(AlertType.highTemp);
      }
    } else {
      _highTempStart = null;
    }

    // ===== LOW TEMP =====
    if (settings.lowTempEnabled &&
        pv != null &&
        pv < settings.lowTempThreshold) {

      _lowTempStart ??= now;

      if (now.difference(_lowTempStart!) >= settings.triggerDelay) {
        active.add(AlertType.lowTemp);
      }
    } else {
      _lowTempStart = null;
    }

    // ===== BATTERY =====
    if (settings.batteryEnabled &&
        batteryPercent != null &&
        batteryPercent < settings.batteryBelowPercent) {

      _batteryStart ??= now;

      if (now.difference(_batteryStart!) >= settings.triggerDelay) {
        active.add(AlertType.batteryLow);
      }
    } else {
      _batteryStart = null;
    }

    // ===== HARD FAILURES (instant) =====
    if (settings.powerFailEnabled && powerFail) active.add(AlertType.powerFail);

    if (settings.probeFailEnabled && probeFail) active.add(AlertType.probeFail);

    if (settings.systemErrorEnabled && systemError) active.add(AlertType.systemError);

    return active;
  }


  void reset() {
    _highTempStart = null;
    _lowTempStart = null;
    _batteryStart = null;
  }
}
