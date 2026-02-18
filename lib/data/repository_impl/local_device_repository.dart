import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../models/registered_device.dart';
import '../repository/device_repository.dart';
import '../api/user_activity_api.dart';
import '../session/session_manager.dart';

class LocalDeviceRepository implements DeviceRepository {
  static const _key = 'registered_devices';
  static const _serialKeyPrefix = "last_device_number";
  static final RegExp _sha256Hex = RegExp(r'^[a-f0-9]{64}$');

  static String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  RegisteredDevice? _safeDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return RegisteredDevice.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// 🔢 ALWAYS INCREMENT — NEVER REUSE
  Future<int> _nextDeviceNumber(String email, String loginType) async {
    final prefs = await SharedPreferences.getInstance();

    final key = "$_serialKeyPrefix$loginType$email";

    final last = prefs.getInt(key) ?? 0;
    final next = last + 1;

    await prefs.setInt(key, next);

    return next;
  }

  @override
  Future<bool> registerDevice(RegisteredDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final email = await SessionManager.getEmail();

    // Remove duplicate entries and prune corrupt rows.
    list.removeWhere((e) {
      final d = _safeDecode(e);
      if (d == null) return true;
      return d.deviceId == device.deviceId;
    });

    // 🔢 Assign serial number ONLY if new device
    int assignedNumber = device.deviceNumber;

    if (assignedNumber <= 0) {
      assignedNumber = await _nextDeviceNumber(
        device.email,
        device.loginType,
      );
    }

    final updatedDevice = RegisteredDevice(
      deviceId: device.deviceId,
      qrCode: device.qrCode,
      productKey: device.productKey,
      serviceType: device.serviceType,
      email: device.email,
      loginType: device.loginType,
      registeredAt: device.registeredAt,
      displayName: device.displayName,
      department: device.department,
      area: device.area,
      pinHash: device.pinHash,
      deviceNumber: assignedNumber,
      modeOp: device.modeOp,
    );

    list.add(jsonEncode(updatedDevice.toJson()));
    await prefs.setStringList(_key, list);

    if (email != null) {
      unawaited(
        UserActivityApi.sendAction(
          email: email,
          action: 'device_added',
          deviceId: device.deviceId,
        ).catchError((_) {}),
      );
    }

    return true;
  }

  @override
  Future<List<RegisteredDevice>> getRegisteredDevices({
    required String email,
    required String loginType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final all = <RegisteredDevice>[];

    var hadCorruptRows = false;
    var hadLegacyPin = false;

    for (final raw in list) {
      final decoded = _safeDecode(raw);
      if (decoded == null) {
        hadCorruptRows = true;
        continue;
      }

      if (!_sha256Hex.hasMatch(decoded.pinHash)) {
        hadLegacyPin = true;

        all.add(
          RegisteredDevice(
            deviceId: decoded.deviceId,
            qrCode: decoded.qrCode,
            productKey: decoded.productKey,
            serviceType: decoded.serviceType,
            email: decoded.email,
            loginType: decoded.loginType,
            registeredAt: decoded.registeredAt,
            displayName: decoded.displayName,
            department: decoded.department,
            area: decoded.area,
            pinHash: _hashPin(decoded.pinHash),
            deviceNumber: decoded.deviceNumber,
            modeOp: "update",
          ),
        );
      } else {
        all.add(decoded);
      }
    }

    // Clean corrupted or legacy rows
    if (hadCorruptRows || hadLegacyPin) {
      await prefs.setStringList(
        _key,
        all.map((d) => jsonEncode(d.toJson())).toList(),
      );
    }

    if (loginType == 'guest') {
      return all.where((d) => d.loginType == 'guest').toList();
    }

    return all.where((d) => d.email == email).toList();
  }

  @override
  Future<bool> hasAnyDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key);
    return list != null && list.isNotEmpty;
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    list.removeWhere((e) {
      final d = _safeDecode(e);
      if (d == null) return true;
      return d.deviceId == deviceId;
    });

    await prefs.setStringList(_key, list);
  }

  Future<void> clearAllDevices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> clearDevicesForUser(String email, String loginType) async {
    final devices = await getRegisteredDevices(
      email: email,
      loginType: loginType,
    );

    for (final d in devices) {
      await deleteDevice(d.deviceId);
    }
  }

  Future<List<RegisteredDevice>> getDevicesForUser(
    String email,
    String loginType,
  ) {
    return getRegisteredDevices(
      email: email,
      loginType: loginType,
    );
  }
}
