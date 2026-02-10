import 'package:flutter/material.dart';

import '../features/splash/splash_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/services/services_screen.dart';
import '../features/dashboard/device_dashboard_screen.dart';
import '../features/devices/add_device/qr_scan_screen.dart';
import '../features/devices/add_device/product_key_screen.dart';
import '../features/devices/add_device/register_device_screen.dart';
import '../features/devices/all_devices_screen.dart';
import '../features/notifications/notification_settings_screen.dart';



class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String auth = '/auth';
  static const String services = '/services';
  static const String dashboard = '/dashboard';
  static const String qrScan = '/qr-scan';
  static const String productKey = '/product-key';
  static const String registerDevice = '/register-device';
  static const String allDevices = '/all-devices';
  static const String notificationSettings = '/notification-settings';




  static Map<String, WidgetBuilder> get routes => {
        

        splash: (_) => const SplashScreen(),
        auth: (_) => const AuthScreen(),
        services: (_) => const ServicesScreen(),
        
        

        // For now, open a default devices list screen.
        // Later we will pass equipmentType dynamically.



        // Dashboard will open for a demo deviceId for now.
        // Later we will open based on user selection.
        dashboard: (_) => const DeviceDashboardScreen(
              deviceId: 'DF-001',
            ),
        qrScan: (_) => const QrScanScreen(),
        productKey: (_) => const ProductKeyScreen(),
        registerDevice: (_) => const RegisterDeviceScreen(),
        allDevices: (_) => const AllDevicesScreen(),

        notificationSettings: (_) => const NotificationSettingsScreen(),
      };
}