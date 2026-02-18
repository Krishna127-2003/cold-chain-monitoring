import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _keyLoggedIn = "is_logged_in";
  static const _keyLoginType = "login_type";
  static const _keyEmail = "email";
  static const String _lastSyncPrefix = "last_sync_";
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static Future<String?> _readSecureWithPrefsFallback(String key) async {
    final secureValue = await _secure.read(key: key);
    if (secureValue != null) return secureValue;

    final prefs = await SharedPreferences.getInstance();
    if (key == _keyLoggedIn) {
      final v = prefs.getBool(_keyLoggedIn);
      if (v == null) return null;
      final migrated = v ? "true" : "false";
      await _secure.write(key: _keyLoggedIn, value: migrated);
      return migrated;
    }

    final legacy = prefs.getString(key);
    if (legacy != null) {
      await _secure.write(key: key, value: legacy);
    }
    return legacy;
  }

  static Future<void> saveLastSync(String deviceId, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("$_lastSyncPrefix$deviceId", time.toIso8601String());
  }

  static Future<DateTime?> getLastSync(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString("$_lastSyncPrefix$deviceId");
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  static Future<void> saveLogin({
    required String loginType,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await _secure.write(key: _keyLoggedIn, value: "true");
    await _secure.write(key: _keyLoginType, value: loginType.trim());
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyLoginType, loginType.trim());

    if (email != null && email.trim().isNotEmpty) {
      final e = email.trim();
      await _secure.write(key: _keyEmail, value: e);
      await prefs.setString(_keyEmail, e);
    } else {
      await _secure.delete(key: _keyEmail);
      await prefs.remove(_keyEmail);
    }
  }

  static Future<bool> isLoggedIn() async {
    final loggedIn = (await _readSecureWithPrefsFallback(_keyLoggedIn)) == "true";
    final type = (await _readSecureWithPrefsFallback(_keyLoginType))?.trim();
    return loggedIn && type != null && type.isNotEmpty;
  }

  static Future<String?> getLoginType() async {
    final type = (await _readSecureWithPrefsFallback(_keyLoginType))?.trim();
    return type?.isNotEmpty == true ? type : null;
  }

  static Future<String?> getEmail() async {
    final email = (await _readSecureWithPrefsFallback(_keyEmail))?.trim();
    return email?.isNotEmpty == true ? email : null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _secure.delete(key: _keyLoggedIn);
    await _secure.delete(key: _keyLoginType);
    await _secure.delete(key: _keyEmail);
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyLoginType);
    await prefs.remove(_keyEmail);
  }
}
