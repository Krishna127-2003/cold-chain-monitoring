import 'package:flutter/services.dart';

class BatteryOptimization {
  static const MethodChannel _channel =
      MethodChannel('battery_optimization');

  static Future<bool> isIgnoringOptimizations() async {
    try {
      return await _channel.invokeMethod<bool>('isIgnoring') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestDisableOnce() async {
    try {
      await _channel.invokeMethod('requestDisable');
    } catch (_) {}
  }
}