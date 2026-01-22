import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _reveal; // 0 -> 1 (left to right)

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    // ✅ Logo reveal starts slow, completes smoothly
    _reveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.85, curve: Curves.easeInOutCubic),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 4600), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.auth);
    });
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
            widthFactor: _reveal.value, // ✅ reveals left -> right
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // ✅ Responsive logo sizing
    final logoHeight = (size.width * 0.28).clamp(80.0, 130.0);

    // ✅ Responsive padding
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
