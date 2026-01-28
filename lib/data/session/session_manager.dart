// ignore_for_file: avoid_print

import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _keyLoggedIn = "is_logged_in";
  static const _keyLoginType = "login_type";
  static const _keyEmail = "email";

  /// ✅ Save login session
  static Future<void> saveLogin({
    required String loginType,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyLoginType, loginType.trim());

    if (email != null && email.trim().isNotEmpty) {
      await prefs.setString(_keyEmail, email.trim());
    } else {
      await prefs.remove(_keyEmail); // ✅ important for guest
    }

    print("💾 Session SAVED: type='$loginType', email='$email'");
  }

  /// ✅ FIXED: Guest OR Google = logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    final type = prefs.getString(_keyLoginType)?.trim();

    final valid = loggedIn && type != null && type.isNotEmpty;

    print("🔍 isLoggedIn(): loggedIn=$loggedIn, type=$type, valid=$valid");
    return valid;
  }

  static Future<String?> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString(_keyLoginType)?.trim();
    return type?.isNotEmpty == true ? type : null;
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail)?.trim();
    return email?.isNotEmpty == true ? email : null;
  }

  /// ✅ Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("🔓 Session CLEARED");
  }
}
