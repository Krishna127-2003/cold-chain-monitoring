import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
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

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  await NotificationService.init();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const ColdChainApp(),
    ),
  );
}

class ColdChainApp extends StatelessWidget {
  const ColdChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cold Chain Monitor',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.mode,
      initialRoute: AppRoutes.splash,
      scaffoldMessengerKey: rootMessengerKey,
      routes: AppRoutes.routes,
    );
  }
}
