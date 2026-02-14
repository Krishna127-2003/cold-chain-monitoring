import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/dashboard/device_dashboard_screen.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';
import 'features/notifications/notification_service.dart';

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

  runApp(const ColdChainApp());
}

class ColdChainApp extends StatelessWidget {
  const ColdChainApp({super.key});

  @override
  Widget build(BuildContext context) {

    final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MarkEn IoT',
      theme: AppTheme.theme,
      initialRoute: AppRoutes.splash,
      scaffoldMessengerKey: rootMessengerKey,
      routes: AppRoutes.routes,

      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.dashboard) {
          final args = settings.arguments as Map<String, dynamic>;

          return MaterialPageRoute(
            builder: (_) => DeviceDashboardScreen(
              deviceId: args["deviceId"],
              equipmentType: args["equipmentType"] ?? "DEEP_FREEZER",
            ),
          );
        }
        return null;
      },
    );
  }
}

