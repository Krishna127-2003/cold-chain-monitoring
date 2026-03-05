// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import '../../core/utils/log_safe.dart';

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
  static const String _baseUrl =
      'https://func-dwin.azurewebsites.net/api';

  /// Normalize email
  static String _prepareEmail(String email) {
    return email.trim().toLowerCase();
  }

  // ─────────────────────────────────────────
  // DEBUG + POST REQUEST
  // ─────────────────────────────────────────
  static Future<HttpClientResponse> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);

    final uri = Uri.parse('$_baseUrl/$path');

    // 🔹 REQUEST DEBUG
    print("API REQUEST → POST $uri");
    print("BODY → ${jsonEncode(data)}");

    final request = await client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');

    request.write(jsonEncode(data));

    final response = await request.close();

    // 🔹 READ RESPONSE BODY
    final responseBody =
        await response.transform(utf8.decoder).join();

    // 🔹 RESPONSE DEBUG
    print("API RESPONSE ← ${response.statusCode}");
    print("BODY ← $responseBody");

    client.close();

    return response;
  }

  // ─────────────────────────────────────────
  // RESPONSE PARSER
  // ─────────────────────────────────────────
  static Future<DwinAuthResult> _handleResponse(
    HttpClientResponse response,
  ) async {
    final body = await response.transform(utf8.decoder).join();

    switch (response.statusCode) {
      case 200:
      case 201:
        return DwinAuthResult(
          success: true,
          message: body.isNotEmpty ? body : 'Success',
        );

      case 403:
        return const DwinAuthResult(
          success: false,
          message: 'Invalid credentials',
          statusCode: 403,
        );

      case 404:
        return const DwinAuthResult(
          success: false,
          message: 'Account not found',
          statusCode: 404,
        );

      case 409:
        return const DwinAuthResult(
          success: false,
          message: 'Account already exists',
          statusCode: 409,
        );

      default:
        return DwinAuthResult(
          success: false,
          message: body.isNotEmpty ? body : 'Request failed',
          statusCode: response.statusCode,
        );
    }
  }

  // ─────────────────────────────────────────
  // CREATE ACCOUNT
  // ─────────────────────────────────────────
  static Future<DwinAuthResult> createAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _post(
        'account',
        {
          'email': _prepareEmail(email),
          'password': password,
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
        },
      );

      return _handleResponse(response);
    } catch (e) {
      logSafe('createAccount error: $e');

      return const DwinAuthResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  // ─────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────
  static Future<DwinAuthResult> checkCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _post(
        'checkCredentials',
        {
          'email': _prepareEmail(email),
          'password': password,
        },
      );

      return _handleResponse(response);
    } catch (e) {
      logSafe('checkCredentials error: $e');

      return const DwinAuthResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  // ─────────────────────────────────────────
  // CHANGE PASSWORD
  // ─────────────────────────────────────────
  static Future<DwinAuthResult> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final client = HttpClient();

      final uri = Uri.parse('$_baseUrl/account');

      print("API REQUEST → PUT $uri");

      final request = await client.putUrl(uri);

      request.headers.set('Content-Type', 'application/json');

      final body = {
        'email': _prepareEmail(email),
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      };

      print("BODY → ${jsonEncode(body)}");

      request.write(jsonEncode(body));

      final response = await request.close();

      final responseBody =
          await response.transform(utf8.decoder).join();

      print("API RESPONSE ← ${response.statusCode}");
      print("BODY ← $responseBody");

      client.close();

      switch (response.statusCode) {
        case 200:
          return const DwinAuthResult(
            success: true,
            message: 'Password changed successfully',
          );

        case 403:
          return const DwinAuthResult(
            success: false,
            message: 'Current password incorrect',
            statusCode: 403,
          );

        default:
          return DwinAuthResult(
            success: false,
            message: 'Password change failed',
            statusCode: response.statusCode,
          );
      }
    } catch (e) {
      logSafe('changePassword error: $e');

      return const DwinAuthResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  // ─────────────────────────────────────────
  // RESET PASSWORD
  // ─────────────────────────────────────────
  static Future<DwinAuthResult> resetPassword({
    required String email,
  }) async {
    try {
      final response = await _post(
        'reset',
        {'email': _prepareEmail(email)},
      );

      if (response.statusCode == 200) {
        final now = DateTime.now();
        final emailLocal = _prepareEmail(email);

        final prefix = emailLocal.length >= 5
            ? emailLocal.substring(0, 5)
            : emailLocal;

        final day = now.day.toString().padLeft(2, '0');

        const months = [
          'JAN','FEB','MR','APR','MAY','JUN',
          'JUL','AUG','SEP','OCT','NOV','DEC'
        ];

        final month = months[now.month - 1];

        final year = now.year.toString().substring(2);

        final password = '$prefix$day$month$year';

        return DwinAuthResult(
          success: true,
          message:
              'Password reset successful. Your new password is: $password',
        );
      }

      return DwinAuthResult(
        success: false,
        message: 'Reset failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      logSafe('resetPassword error: $e');

      return const DwinAuthResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }
}