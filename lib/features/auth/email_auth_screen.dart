import 'package:flutter/material.dart';
import 'dwin_auth_service.dart';
import '../../data/session/session_manager.dart';
import '../../data/repository/device_repository.dart';
import '../../data/repository_impl/local_device_repository.dart';
import '../../data/api/user_info_api.dart';
import '../../routes/app_routes.dart';

/// ✅ Email/Password login screen (Dwin Auth)
/// Shown when user taps "Continue with Email" on AuthScreen
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final DeviceRepository _deviceRepo = LocalDeviceRepository();

  bool _isLogin = true; // toggle between login and register
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (_isLogin) {
      await _handleLogin(email, password);
    } else {
      await _handleRegister(email, password);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handleLogin(String email, String password) async {
    final result = await DwinAuthService.checkCredentials(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (result.success) {
      await _completeLogin(email);
    } else {
      // 404 = not registered → suggest registration
      if (result.statusCode == 404) {
        _showDialog(
          title: 'Account Not Found',
          message: 'No account found for this email. Would you like to register?',
          action: 'Register',
          onAction: () => setState(() => _isLogin = false),
        );
      } else {
        _showSnack(result.message ?? 'Login failed');
      }
    }
  }

  Future<void> _handleRegister(String email, String password) async {
    final result = await DwinAuthService.createAccount(
      email: email,
      password: password,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (!mounted) return;

    if (result.success) {
      await _completeLogin(email);
    } else if (result.statusCode == 409) {
      // Already exists → switch to login
      _showDialog(
        title: 'Account Exists',
        message: 'An account with this email already exists. Please login instead.',
        action: 'Login',
        onAction: () => setState(() => _isLogin = true),
      );
    } else {
      _showSnack(result.message ?? 'Registration failed');
    }
  }

  Future<void> _completeLogin(String email) async {
    try {
      final exists = await UserInfoApi.doesUserExist(email);
      if (!exists) {
        await UserInfoApi.sendUserLogin(
          email: email,
          loginType: 'email',
        );
      }

      await SessionManager.saveLogin(
        loginType: 'email',
        email: email,
      );

      await _deviceRepo.getRegisteredDevices(
        email: email,
        loginType: 'email',
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.allDevices);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Login flow failed. Please try again.');
    }
  }

  Future<void> _onForgotPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      _showSnack('Please enter your email first');
      return;
    }

    setState(() => _loading = true);
    final result = await DwinAuthService.resetPassword(email: email);
    if (!mounted) return;
    setState(() => _loading = false);

    _showDialog(
      title: result.success ? 'Password Reset' : 'Reset Failed',
      message: result.message ?? '',
      action: 'OK',
      onAction: () {},
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showDialog({
    required String title,
    required String message,
    required String action,
    required VoidCallback onAction,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onAction();
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLogin ? 'Welcome Back' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLogin
                            ? 'Sign in to your account'
                            : 'Register a new account',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── First + Last name (register only) ──
                      if (!_isLogin) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _InputField(
                                controller: _firstNameController,
                                label: 'First Name',
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InputField(
                                controller: _lastNameController,
                                label: 'Last Name',
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Email ──
                      _InputField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // ── Password ──
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),

                      // ── Forgot Password ──
                      if (_isLogin) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _onForgotPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF60A5FA),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── Submit Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Sign In' : 'Create Account',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Toggle Login/Register ──
                      Center(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLogin = !_isLogin),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: _isLogin
                                      ? "Don't have an account? "
                                      : 'Already have an account? ',
                                ),
                                TextSpan(
                                  text: _isLogin ? 'Register' : 'Sign In',
                                  style: const TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }
}