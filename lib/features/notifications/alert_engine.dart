import 'alert_utils.dart';
import 'alert_settings.dart';

class AlertEngine {
  DateTime? _abnormalStart;

  bool shouldTrigger({
    required double pv,
    required double sv,
    required AlertSettings settings,
  }) {
    // back to normal
    if (pv <= sv) {
      _abnormalStart = null;
      return false;
    }

    // first abnormal moment
    _abnormalStart ??= DateTime.now();

    final delay = levelToDelay(settings.level);

    return DateTime.now().difference(_abnormalStart!) >= delay;
  }

  void reset() {
    _abnormalStart = null;
  }
}
