// ignore_for_file: unreachable_switch_default

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/utils/responsive.dart';
import '../../core/theme/theme_provider.dart';
import '../../routes/app_routes.dart';
import 'google_auth_service.dart';
import '../../data/session/session_manager.dart'; // ✅ NEW


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _loadingGoogle = false;
  bool _loadingGuest = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    Navigator.pushReplacementNamed(context, AppRoutes.services);
  }


  Future<void> _onGooglePressed() async {
    setState(() => _loadingGoogle = true);

    final userCredential = await GoogleAuthService.signInWithGoogle();

    if (!mounted) return;

    if (userCredential == null) {
      setState(() => _loadingGoogle = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Google Sign-In failed. Try again."),
        ),
      );
      return;
    }

     /// ✅ SAVE LOGIN SESSION
    await SessionManager.saveLogin(
      loginType: "google",
      email: userCredential.user?.email,
    );

    setState(() => _loadingGoogle = false);

    // ✅ Success → go to services screen
    await _goNext();
  }

  Future<void> _onGuestPressed() async {
    setState(() => _loadingGuest = true);

    await Future.delayed(const Duration(milliseconds: 550));

    if (!mounted) return;

     /// ✅ SAVE GUEST SESSION
    await SessionManager.saveLogin(loginType: "guest");

    setState(() => _loadingGuest = false);

    await _goNext();
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pad(context);
    final themeProvider = context.watch<ThemeProvider>();

    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ background gradient depends on dark/light
    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF050A18),
              Color(0xFF08112A),
              Color(0xFF060B1C),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF7FAFF),
              Color(0xFFEFF6FF),
              Color(0xFFECFEFF),
            ],
          );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: bgGradient),
        child: Stack(
          children: [
            // ✅ floating blur circles background
            _GlowBlob(
              top: -90,
              left: -90,
              size: 250,
              color: isDark ? const Color(0xFF1D4ED8) : const Color(0xFF93C5FD),
            ),
            _GlowBlob(
              top: 150,
              right: -110,
              size: 260,
              color: isDark ? const Color(0xFF0EA5E9) : const Color(0xFFBAE6FD),
            ),
            _GlowBlob(
              bottom: -110,
              left: 60,
              size: 280,
              color: isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE),
            ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(pad),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Stack(
                      children: [
                        // ✅ Main Card
                        Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: isSmall ? 18 : 22,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.10,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 30,
                                          offset: const Offset(0, 18),
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.50 : 0.10,
                                          ),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        /// ✅ FIX: remove white background behind SVG in dark mode
                                        ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                            Colors.transparent,
                                            BlendMode.srcATop,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.all(
                                                color: Colors.black.withValues(alpha: 0.06),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 10),
                                                  color: Colors.black.withValues(alpha: 0.25),
                                                ),
                                              ],
                                            ),
                                            child: SvgPicture.asset(
                                              "assets/images/marken_logo.svg",
                                              height: isSmall ? 58 : 66,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        Text(
                                          "Welcome to Cold Chain Monitor",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        Text(
                                          "Securely onboard devices and monitor critical hospital equipment in real time.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white70
                                                : const Color(0xFF475569),
                                            height: 1.35,
                                          ),
                                        ),

                                        SizedBox(height: isSmall ? 16 : 20),

                                        // ✅ Google Sign-In Button
                                        _AuthButton(
                                          text: "Continue with Google",
                                          loading: _loadingGoogle,
                                          onPressed: _loadingGuest
                                              ? null
                                              : _onGooglePressed,
                                          icon: const _GoogleIcon(size: 24),
                                          filled: true,
                                          darkMode: isDark,
                                        ),

                                        const SizedBox(height: 12),

                                        // ✅ Guest Button
                                        _AuthButton(
                                          text: "Continue as Guest",
                                          loading: _loadingGuest,
                                          onPressed: _loadingGoogle
                                              ? null
                                              : _onGuestPressed,
                                          icon: Icon(
                                            Icons.person_outline,
                                            size: 22,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                          filled: false,
                                          darkMode: isDark,
                                        ),

                                        const SizedBox(height: 14),

                                        Text(
                                          "New here? Google Sign-In creates your account automatically.\nAlready registered? It signs you back in instantly.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            height: 1.35,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white60
                                                : const Color(0xFF64748B),
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () {},
                                              child: const Text(
                                                "Terms",
                                                style: TextStyle(
                                                  color: Color(0xFF2563EB),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const Text(
                                              "  •  ",
                                              style: TextStyle(
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {},
                                              child: const Text(
                                                "Privacy",
                                                style: TextStyle(
                                                  color: Color(0xFF2563EB),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ✅ Theme toggle (Top Right like modern apps)
                        Positioned(
                          top: 6,
                          right: 4,
                          child: _ThemeMenuButton(
                            currentMode: themeProvider.mode,
                            onModeSelected: (mode) {
                              themeProvider.setTheme(mode);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Theme Menu Button (System / Light / Dark)
class _ThemeMenuButton extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onModeSelected;

  const _ThemeMenuButton({
    required this.currentMode,
    required this.onModeSelected,
  });

  IconData _iconForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
      default:
        return Icons.settings_suggest_rounded;
    }
  }

  String _labelForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return "Light";
      case ThemeMode.dark:
        return "Dark";
      case ThemeMode.system:
      default:
        return "System";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<ThemeMode>(
      tooltip: "Theme",
      onSelected: onModeSelected,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: ThemeMode.system,
          child: Text("System"),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: Text("Light"),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Text("Dark"),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.04),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForMode(currentMode),
              size: 18,
              color: isDark ? Colors.white70 : const Color(0xFF0F172A),
            ),
            const SizedBox(width: 8),
            Text(
              _labelForMode(currentMode),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Premium Button widget with loading animation
class _AuthButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final bool filled;
  final bool loading;
  final VoidCallback? onPressed;
  final bool darkMode;

  const _AuthButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.loading,
    required this.filled,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    final border = darkMode
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.10);

    final bg = filled
        ? Colors.white
        : (darkMode
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF8FAFC));

    final fg = filled
        ? const Color(0xFF0F172A)
        : (darkMode ? Colors.white : const Color(0xFF0F172A));

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: border),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: loading
              ? const SizedBox(
                  key: ValueKey("loading"),
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  key: const ValueKey("content"),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(width: 10),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// ✅ Real Google G Icon (No asset needed)
class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    const googleSvg = '''
<svg width="24" height="24" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.18 1.54 7.6 2.83l5.53-5.53C33.64 3.44 29.24 1.5 24 1.5 14.75 1.5 6.85 6.92 3.38 14.77l6.43 4.99C11.3 13.29 17.15 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.5 24.5c0-1.54-.14-3.02-.39-4.44H24v8.4h12.66c-.54 2.9-2.14 5.36-4.56 7.03l7 5.44c4.09-3.78 6.4-9.34 6.4-16.43z"/>
  <path fill="#FBBC05" d="M9.81 28.24c-.43-1.29-.68-2.66-.68-4.06s.25-2.77.68-4.06l-6.43-4.99C2.29 17.57 1.5 20.68 1.5 24.18s.79 6.61 1.88 9.05l6.43-4.99z"/>
  <path fill="#34A853" d="M24 46.5c5.24 0 9.64-1.73 12.85-4.72l-7-5.44c-1.94 1.3-4.44 2.07-5.85 2.07-6.85 0-12.7-3.79-14.19-9.26l-6.43 4.99C6.85 41.08 14.75 46.5 24 46.5z"/>
</svg>
''';

    return SvgPicture.string(
      googleSvg,
      height: size,
      width: size,
    );
  }
}

/// ✅ floating blur circles background
class _GlowBlob extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  const _GlowBlob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.45),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
            child: const SizedBox(),
          ),
        ),
      ),
    );
  }
}
