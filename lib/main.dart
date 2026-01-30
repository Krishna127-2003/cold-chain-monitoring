import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';
import 'core/ui/app_snackbar.dart';

/// ✅ ONE global key (top-level, not inside widgets)
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
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

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  /// ✅ Initialize SnackBar controller ONCE
  AppSnackBar.init(rootMessengerKey);

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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cold Chain Monitor',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.mode,
      initialRoute: AppRoutes.splash,

      /// ✅ Attach GLOBAL messenger
      scaffoldMessengerKey: rootMessengerKey,

      /// ✅ Attach navigator observer (kills SnackBars on route change)
      navigatorObservers: const [SnackBarRouteObserver()],

      routes: AppRoutes.routes,
    );
  }
}
