import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../routes/app_routes.dart';
import '../../data/session/session_manager.dart';
import '../../data/repository/device_repository.dart';
import '../../data/repository_impl/local_device_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _reveal;

  bool _navigated = false;

  final DeviceRepository _deviceRepo = LocalDeviceRepository();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _reveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.85, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
    _decideNext();
  }

  Future<void> _decideNext() async {
    await Future.delayed(const Duration(milliseconds: 4600));

    if (!mounted || _navigated) return;
    _navigated = true;

    final loggedIn = await SessionManager.isLoggedIn();

    if (!loggedIn) {
      print("➡️ Splash → Auth");
      _go(AppRoutes.auth);
      return;
    }

    final loginType = await SessionManager.getLoginType();
    final email = await SessionManager.getEmail();

    if (loginType == null) {
      print("❌ Invalid session → Auth");
      await SessionManager.logout();
      _go(AppRoutes.auth);
      return;
    }

    final devices = await _deviceRepo.getRegisteredDevices(
      email: email ?? "",
      loginType: loginType,
    );

    if (!mounted) return;

    if (devices.isEmpty) {
      print("➡️ Splash → Services (no devices)");
      _go(AppRoutes.services);
    } else {
      print("➡️ Splash → AllDevices (${devices.length})");
      _go(AppRoutes.allDevices);
    }
  }

  void _go(String route) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _revealFromLeft({required Widget child}) {
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: _reveal.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoHeight = (size.width * 0.28).clamp(80.0, 130.0);
    final padding = (size.width * 0.08).clamp(18.0, 32.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Center(
            child: _revealFromLeft(
              child: SvgPicture.asset(
                "assets/images/marken_logo.svg",
                height: logoHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
