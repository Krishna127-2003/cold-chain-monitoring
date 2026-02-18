import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/dashboard/device_dashboard_screen.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';
import 'features/notifications/notification_service.dart';
import 'core/ui/app_snackbar.dart';

final GlobalKey<ScaffoldMessengerState> _rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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

