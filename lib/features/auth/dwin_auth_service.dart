// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import '../../core/utils/log_safe.dart';

/// ✅ Encoding utility — Base64
/// Always lowercase email before encoding
class _Encoder {
  static String encode(String value) {
    return base64.encode(utf8.encode(value));
  }


}

class DwinAuthResult {
  final bool success;
  final String? message;
  final int? statusCode;

  const DwinAuthResult({
    required this.success,
    this.message,
    this.statusCode,
  });
}

class DwinAuthService {
  static const String _baseUrl = 'https://func-dwin.azurewebsites.net/api';

  /// ✅ Always lowercase + encode email
  static String _prepareEmail(String email) {
    return _Encoder.encode(email.trim().toLowerCase());
  }

  static String _preparePassword(String password) {
    return _Encoder.encode(password);
  }

  // ─────────────────────────────────────────
  // 1. Create Account
  // ─────────────────────────────────────────
  static Future<DwinAuthResult> createAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$_baseUrl/account');
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'email': _prepareEmail(email),
        'password': _preparePassword(password),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
      });

      request.write(body);
      final response = await request.close();
      client.close();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const DwinAuthResult(success: true, message: 'Account created successfully');
      } else if (response.statusCode == 409) {
        return const DwinAuthResult(success: false, message: 'Account already exists', statusCode: 409);
      } else {
        return DwinAuthResult(success: false, message: 'Failed to create account', statusCode: response.statusCode);
      }
    } catch (e) {
      logSafe('DwinAuth createAccount error: $e');
      return const DwinAuthResult(success: false, message: 'Network error. Please try again.');
    }
  }

  // ─────────────────────────────────────────
  // 2. Check Credentials (Login)
  // ─────────────────────────────────────────
  static Future<DwinAuthResult> checkCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$_baseUrl/checkCredentials');
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'email': _prepareEmail(email),
        'password': _preparePassword(password),
      });

      request.write(body);
      final response = await request.close();
      client.close();

      switch (response.statusCode) {
        case 200:
          return const DwinAuthResult(success: true, message: 'Login successful');
        case 403:
          return const DwinAuthResult(success: false, message: 'Invalid credentials. Please check your password.', statusCode: 403);
        case 404:
          return const DwinAuthResult(success: false, message: 'Account not found. Please register first.', statusCode: 404);
        default:
          return DwinAuthResult(success: false, message: 'Login failed. Please try again.', statusCode: response.statusCode);
      }
    } catch (e) {
      logSafe('DwinAuth checkCredentials error: $e');
      return const DwinAuthResult(success: false, message: 'Network error. Please try again.');
    }
  }

  // ─────────────────────────────────────────
  // 3. Change Password
  // ─────────────────────────────────────────
  static Future<DwinAuthResult> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$_baseUrl/account');
      final request = await client.putUrl(uri);

      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'email': _prepareEmail(email),
        'oldPassword': _preparePassword(oldPassword),
        'newPassword': _preparePassword(newPassword),
      });

      request.write(body);
      final response = await request.close();
      client.close();

      if (response.statusCode == 200) {
        return const DwinAuthResult(success: true, message: 'Password changed successfully');
      } else if (response.statusCode == 403) {
        return const DwinAuthResult(success: false, message: 'Current password is incorrect', statusCode: 403);
      } else {
        return DwinAuthResult(success: false, message: 'Failed to change password', statusCode: response.statusCode);
      }
    } catch (e) {
      logSafe('DwinAuth changePassword error: $e');
      return const DwinAuthResult(success: false, message: 'Network error. Please try again.');
    }
  }

  // ─────────────────────────────────────────
  // 4. Reset Password
  // ─────────────────────────────────────────
  static Future<DwinAuthResult> resetPassword({
    required String email,
  }) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$_baseUrl/reset');
      final request = await client.postUrl(uri);

      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'email': _prepareEmail(email),
      });

      request.write(body);
      final response = await request.close();
      client.close();

      if (response.statusCode == 200) {
        // Generate the expected reset password locally so user knows what it is
        final now = DateTime.now();
        final emailLocal = email.trim().toLowerCase();
        final prefix = emailLocal.length >= 5
            ? emailLocal.substring(0, 5)
            : emailLocal;
        final day = now.day.toString().padLeft(2, '0');
        const months = ['JAN','FEB','MR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
        final month = months[now.month - 1];
        final year = now.year.toString().substring(2);
        final generatedPassword = '$prefix$day$month$year';

        return DwinAuthResult(
          success: true,
          message: 'Password reset successful. Your new password is: $generatedPassword',
        );
      } else {
        return DwinAuthResult(
          success: false,
          message: 'Reset failed. Account may not exist.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      logSafe('DwinAuth resetPassword error: $e');
      return const DwinAuthResult(success: false, message: 'Network error. Please try again.');
    }
  }
}