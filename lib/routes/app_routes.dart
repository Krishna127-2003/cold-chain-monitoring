import 'package:flutter/material.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/services/services_screen.dart';
import '../features/devices/add_device/qr_scan_screen.dart';
import '../features/devices/add_device/product_key_screen.dart';
import '../features/devices/add_device/register_device_screen.dart';
import '../features/devices/all_devices_screen.dart';
import '../features/notifications/notification_settings_screen.dart';
import '../features/devices/add_device/manual_entry_screen.dart';
import '../features/devices/edit_device_screen.dart';
import '../features/alerts_history/alert_history_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String services = '/services';
  static const String dashboard = '/dashboard';
  static const String qrScan = '/qr-scan';
  static const String productKey = '/product-key';
  static const String registerDevice = '/register-device';
  static const String allDevices = '/all-devices';
  static const String notificationSettings = '/notification-settings';
  static const String manualEntry = "/manualEntry"; 
  static const editDevice = "/editDevice"; // 👈 ADD THIS
  static const alertHistory = "/alert-history";

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        auth: (_) => const AuthScreen(),
        services: (_) => const ServicesScreen(),
        qrScan: (_) => const QrScanScreen(),
        productKey: (_) => const ProductKeyScreen(),
        registerDevice: (_) => const RegisterDeviceScreen(),
        allDevices: (_) => const AllDevicesScreen(),
        notificationSettings: (_) => const NotificationSettingsScreen(),
        manualEntry: (_) => const ManualEntryScreen(),   // ✅ NEW
        editDevice: (_) => const EditDeviceScreen(),
        alertHistory: (_) => const AlertHistoryScreen(),
      };
}
