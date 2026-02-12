import 'alert_engine.dart';
import 'alert_settings.dart';
import 'alert_settings_storage.dart';
import 'notification_service.dart';

class AlertProcessor {
  final AlertEngine _engine = AlertEngine();

  Future<void> process({
    required double pv,
    required double sv,
  }) async {
    final settingsMap = await AlertSettingsStorage.load();
    final settings = AlertSettings.fromJson(settingsMap);

    final shouldFire = _engine.shouldTrigger(
      pv: pv,
      sv: sv,
      settings: settings,
    );

    if (!shouldFire) return;

    if (settings.app) {
      await NotificationService.sendRepeated(
        "Cold Chain Alert",
        "Temperature exceeded safe range",
      );
    }

    // Later you can plug email + sms here
  }

  void reset() => _engine.reset();
}

