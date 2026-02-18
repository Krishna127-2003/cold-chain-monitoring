import 'alert_settings.dart';
import 'equipment_standards.dart';

class AlertEngine {
  DateTime? _highTempStart;
  DateTime? _lowTempStart;
  DateTime? _batteryStart;

  bool shouldTrigger({
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

    // ===== HIGH TEMP =====
    if (settings.highTempEnabled &&
        pv != null &&
        pv > settings.highTempThreshold) {

      _highTempStart ??= now;

      if (now.difference(_highTempStart!) >= settings.triggerDelay) {
        return true;
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
        return true;
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
        return true;
      }
    } else {
      _batteryStart = null;
    }

    // ===== HARD FAILURES (instant) =====
    if (settings.powerFailEnabled && powerFail) return true;
    if (settings.probeFailEnabled && probeFail) return true;
    if (settings.systemErrorEnabled && systemError) return true;

    return false;
  }


  void reset() {
    _highTempStart = null;
    _lowTempStart = null;
    _batteryStart = null;
  }
}
