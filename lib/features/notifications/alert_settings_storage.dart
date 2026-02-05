import 'package:shared_preferences/shared_preferences.dart';

class AlertSettingsStorage {

  static Future<void> save({
    required bool app,
    required bool email,
    required bool sms,
    required int level,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("alert_app", app);
    await prefs.setBool("alert_email", email);
    await prefs.setBool("alert_sms", sms);
    await prefs.setInt("alert_level", level);
  }

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "app": prefs.getBool("alert_app") ?? true,
      "email": prefs.getBool("alert_email") ?? true,
      "sms": prefs.getBool("alert_sms") ?? true,
      "level": prefs.getInt("alert_level") ?? 1,
    };
  }
}
