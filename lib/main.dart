import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/dashboard/device_dashboard_screen.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';
import 'features/notifications/notification_service.dart';
import 'core/ui/app_snackbar.dart';
import 'package:workmanager/workmanager.dart';
import 'data/session/session_manager.dart';
import 'data/api/device_management_api.dart';
import 'data/api/android_data_api.dart';
import 'features/notifications/alert_manager.dart';

final GlobalKey<ScaffoldMessengerState> _rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    await NotificationService.init();

    try {
      // Get email
      final email = await SessionManager.getEmail();
      if (email == null) return true;

      // Get devices from backend
      final devices = await DeviceManagementApi.listDevices(email);

      for (final row in devices) {
        final deviceId = row["deviceId"]?.toString();
        final deviceType = row["deviceType"]?.toString() ?? "DEEP_FREEZER";

        if (deviceId == null) continue;

        final telemetry =
            await AndroidDataApi.fetchByDeviceId(deviceId);

        if (telemetry == null) continue;

        await AlertManager.handleTelemetry(
          deviceId: deviceId,
          equipmentType: deviceType,
          temperature: telemetry.pv,
          sv: telemetry.sv,
          batteryPercent: telemetry.battery,
          powerFail: !telemetry.powerOn,
          probeFail: !telemetry.probeOk,
          systemError: !telemetry.systemHealthy,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}


  await NotificationService.init();
  await NotificationService.requestPermission();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  await Workmanager().registerPeriodicTask(
    "alert-worker",
    "alert-worker",
    frequency: const Duration(minutes: 15),

    existingWorkPolicy: ExistingWorkPolicy.keep,

    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: false,
      requiresCharging: false,
    ),
  );

  runApp(const ColdChainApp());
}

class ColdChainApp extends StatelessWidget {
  const ColdChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppSnackBar.init(_rootMessengerKey);


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MarkEn IoT',
      theme: AppTheme.theme,
      initialRoute: AppRoutes.splash,
      scaffoldMessengerKey: _rootMessengerKey,
      routes: AppRoutes.routes,

      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.dashboard) {
          final args = settings.arguments;
          if (args is! Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (_) => const DeviceDashboardScreen(
                deviceId: "UNKNOWN",
                equipmentType: "DEEP_FREEZER",
              ),
            );
          }

          return MaterialPageRoute(
            builder: (_) => DeviceDashboardScreen(
              deviceId: (args["deviceId"] ?? "UNKNOWN").toString(),
              equipmentType: (args["equipmentType"] ?? "DEEP_FREEZER")
                  .toString(),
            ),
          );
        }
        return null;
      },
    );
  }
}

