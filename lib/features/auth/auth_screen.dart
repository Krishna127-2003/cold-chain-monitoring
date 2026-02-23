// ignore_for_file: unreachable_switch_default

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/responsive.dart';
import '../../routes/app_routes.dart';
import 'google_auth_service.dart';
import '../../data/session/session_manager.dart'; // ✅ NEW
import '../../data/repository/device_repository.dart';
import '../../data/repository_impl/local_device_repository.dart';
import '../../data/api/user_info_api.dart';
import 'privacy_policy_screen.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const String policyVersion = "2026-02-04";

  @override
  State<AuthScreen> createState() => _AuthScreenState();
  
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  final DeviceRepository _deviceRepo = LocalDeviceRepository();


  bool _loadingGoogle = false;
  bool _loadingGuest = false;
  bool acceptedPolicy = false;


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
    _loadPolicyAcceptance();

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPolicyAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getString("accepted_policy_version");

    if (!mounted) return;

    if (savedVersion == AuthScreen.policyVersion) {
      setState(() => acceptedPolicy = true);
    }
  }

  Future<void> _goNext() async {
    Navigator.pushReplacementNamed(context, AppRoutes.allDevices  );
  }


  Future<void> _onGooglePressed() async {
    if (!acceptedPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept Privacy Policy to continue")),
      );
      return;
    }

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

    final email = userCredential.user?.email;
    if (email == null || email.trim().isEmpty) {
      if (!mounted) return;
      setState(() => _loadingGoogle = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Google account email is unavailable."),
        ),
      );
      return;
    }

    try {
      final exists = await UserInfoApi.doesUserExist(email);

      if (!exists) {
        await UserInfoApi.sendUserLogin(
          email: email,
          loginType: "google",
        );
      }

      await SessionManager.saveLogin(
        loginType: "google",
        email: email,
      );

      await _deviceRepo.getRegisteredDevices(
        email: email,
        loginType: "google",
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.allDevices);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google sign-in flow failed.")),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingGoogle = false);
      }
    }
  }
  Future<void> _onGuestPressed() async {
    if (!acceptedPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept Privacy Policy to continue")),
      );
      return;
    }

    setState(() => _loadingGuest = true);

    await Future.delayed(const Duration(milliseconds: 550));

    if (!mounted) return;

    final guestBackendId =
        "guest_${DateTime.now().millisecondsSinceEpoch}@markenworld.com";

        debugPrint("Guest email being sent: $guestBackendId");
        
    try {
      final exists = await UserInfoApi.doesUserExist(guestBackendId);

      if (!exists) {
        await UserInfoApi.sendUserLogin(
          email: guestBackendId,
          loginType: "guest",
        );
      }

      await SessionManager.saveLogin(
        loginType: "guest",
        email: guestBackendId,
      );

      if (!mounted) return;
      await _goNext();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guest sign-in failed.")),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingGuest = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pad(context);

    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    const bgGradient = LinearGradient(
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
              color: const Color(0xFF93C5FD),
            ),
            _GlowBlob(
              top: 150,
              right: -110,
              size: 260,
              color: const Color(0xFFBAE6FD),
            ),
            _GlowBlob(
              bottom: -110,
              left: 60,
              size: 280,
              color: const Color(0xFFBFDBFE),
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
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.black.withValues(alpha: 0.06),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 30,
                                          offset: const Offset(0, 18),
                                          color: Colors.black.withValues(
                                            alpha: 0.10,
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
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 6),

                                        Text(
                                          "Securely onboard devices and monitor critical hospital equipment in real time.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF475569),
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
                                            color: const Color(0xFF0F172A),
                                          ),
                                          filled: false,
                                          
                                        ),

                                        const SizedBox(height: 14),

                                        Text(
                                          "New here? Google Sign-In creates your account automatically.\nAlready registered? It signs you back in instantly.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            height: 1.35,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Checkbox(
                                                  value: acceptedPolicy,
                                                  activeColor: const Color(0xFF60A5FA),
                                                  onChanged: (v) async {
                                                    final accepted = v ?? false;
                                                    if (mounted) {
                                                      setState(() => acceptedPolicy = accepted);
                                                    }
                                                    final prefs = await SharedPreferences.getInstance();

                                                    if (accepted) {
                                                      await prefs.setString(
                                                        "accepted_policy_version",
                                                        AuthScreen.policyVersion,
                                                      );
                                                    } else {
                                                      await prefs.remove(
                                                        "accepted_policy_version",
                                                      );
                                                    }
                                                  },
                                                ),
                                                Text(
                                                  "I agree to the ",
                                                  style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF64748B),
                                                          )
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => const PrivacyPolicyScreen(),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text(
                                                    "Privacy Policy",
                                                    style: TextStyle(
                                                      color: Color(0xFF60A5FA),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 6),

                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const PrivacyPolicyScreen(),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                "Read our Privacy Policy to learn how we protect your data.",
                                                style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF64748B),
                                                        )
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),
                                        const SizedBox.shrink(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
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

/// ✅ Premium Button widget with loading animation
class _AuthButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final bool filled;
  final bool loading;
  final VoidCallback? onPressed;

  const _AuthButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.loading,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final border = Colors.black.withValues(alpha: 0.10);
    final bg = filled ? Colors.white : const Color(0xFFF8FAFC);
    const fg = Color(0xFF0F172A);

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



