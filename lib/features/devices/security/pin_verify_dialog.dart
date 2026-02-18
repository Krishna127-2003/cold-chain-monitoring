import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../../../data/api/user_info_api.dart';
import '../../../data/repository_impl/local_device_repository.dart';
import '../../../data/session/session_manager.dart';

class PinVerifyDialog {
  static String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  static bool _matchesPin(String enteredPin, String storedPinOrHash) {
    return _hashPin(enteredPin) == storedPinOrHash.trim();
  }

  static Future<bool> verify(
    BuildContext context, {
    required String deviceId,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _PinVerifyDialogBody(deviceId: deviceId),
        ) ??
        false;
  }
}

class _PinVerifyDialogBody extends StatefulWidget {
  final String deviceId;

  const _PinVerifyDialogBody({required this.deviceId});

  @override
  State<_PinVerifyDialogBody> createState() => _PinVerifyDialogBodyState();
}

class _PinVerifyDialogBodyState extends State<_PinVerifyDialogBody> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _forgotPin() async {
    try {
      final email = await SessionManager.getEmail();

      if (email == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN is stored locally in guest mode.'),
          ),
        );
        return;
      }

      await UserInfoApi.postData({
        'type': 'forgot_pin_request',
        'email': email,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN recovery request sent')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send PIN recovery')),
      );
    }
  }

  Future<void> _confirm() async {
    final now = DateTime.now();
    if (_lockedUntil != null && now.isBefore(_lockedUntil!)) {
      final secs = _lockedUntil!.difference(now).inSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Too many attempts. Try again in $secs seconds'),
        ),
      );
      return;
    }

    final enteredPin = _controller.text.trim();
    if (enteredPin.isEmpty) return;

    setState(() => _loading = true);
    var closed = false;
    try {
      final loginType = await SessionManager.getLoginType() ?? 'guest';
      final email = await SessionManager.getEmail();

      final repo = LocalDeviceRepository();
      final devices = await repo.getRegisteredDevices(
        email: loginType == 'guest' ? '' : (email ?? ''),
        loginType: loginType,
      );

      var verified = false;
      for (final d in devices) {
        if (d.deviceId == widget.deviceId) {
          verified = PinVerifyDialog._matchesPin(enteredPin, d.pinHash);
          break;
        }
      }

      if (!mounted) return;
      if (verified) {
        _failedAttempts = 0;
        _lockedUntil = null;
        closed = true;
        Navigator.pop(context, true);
      } else {
        _failedAttempts += 1;
        if (_failedAttempts >= 5) {
          _lockedUntil = DateTime.now().add(const Duration(minutes: 1));
          _failedAttempts = 0;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect PIN')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN verification failed')),
      );
    } finally {
      if (mounted && !closed) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm with PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Enter PIN'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _forgotPin,
            child: const Text('Forgot PIN?'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _confirm,
          child: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }
}
