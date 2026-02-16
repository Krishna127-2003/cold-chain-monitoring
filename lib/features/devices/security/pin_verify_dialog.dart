import 'package:flutter/material.dart';

import '../../../data/api/user_info_api.dart';
import '../../../data/session/session_manager.dart';
import '../../../data/repository_impl/local_device_repository.dart';
import '../../../data/models/registered_device.dart';

class PinVerifyDialog {
  static Future<bool> verify(
    BuildContext context, {
    required String deviceId,
  }) async {
    final controller = TextEditingController();
    bool loading = false;

    try {
      return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              return StatefulBuilder(
                builder: (ctx, setState) {
                  return AlertDialog(
                  title: const Text("Confirm with PIN"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Enter PIN",
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          final email = await SessionManager.getEmail();

                          if (email == null) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "PIN is stored locally in guest mode."),
                              ),
                            );
                            return;
                          }

                          await UserInfoApi.postData({
                            "type": "forgot_pin_request",
                            "email": email,
                          });

                          if (!ctx.mounted) return;

                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text("PIN recovery request sent"),
                            ),
                          );
                        },
                        child: const Text("Forgot PIN?"),
                      )
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              final enteredPin = controller.text.trim();
                              if (enteredPin.isEmpty) return;

                              setState(() => loading = true);

                              final loginType =
                                  await SessionManager.getLoginType() ?? "guest";
                              final email =
                                  await SessionManager.getEmail();

                              bool verified = false;

                              // ===============================
                              // 👤 GUEST MODE → LOCAL PIN CHECK
                              // ===============================
                              if (loginType == "guest" || email == null) {
                                final repo = LocalDeviceRepository();

                                final devices =
                                    await repo.getRegisteredDevices(
                                  email: "",
                                  loginType: "guest",
                                );

                                final device = devices.firstWhere(
                                  (d) => d.deviceId == deviceId,
                                  orElse: () => RegisteredDevice(
                                    deviceId: "",
                                    qrCode: "",
                                    productKey: "",
                                    serviceType: "",
                                    email: "",
                                    loginType: "guest",
                                    registeredAt: DateTime.now(),
                                    displayName: "",
                                    department: "",
                                    area: "",
                                    pin: "",
                                  ),
                                );

                                verified = device.pin == enteredPin;
                              }

                              // ===============================
                              // ☁ GOOGLE LOGIN → AZURE + FALLBACK
                              // ===============================
                              else {
                                final rows =
                                    await UserInfoApi.fetchByEmail(email);

                                final pinRow = rows.firstWhere(
                                  (r) =>
                                      r["type"] == "device_registration" &&
                                      r["deviceId"] == deviceId,
                                  orElse: () => {},
                                );

                                final savedPin =
                                    pinRow["pin"]?.toString();

                                if (savedPin != null) {
                                  verified = savedPin == enteredPin;
                                } else {
                                  // 🔥 FALLBACK TO LOCAL AFTER UNDO
                                  final repo = LocalDeviceRepository();

                                  final devices =
                                      await repo.getRegisteredDevices(
                                    email: email,
                                    loginType: loginType,
                                  );

                                  final device = devices.firstWhere(
                                    (d) => d.deviceId == deviceId,
                                    orElse: () => RegisteredDevice(
                                      deviceId: "",
                                      qrCode: "",
                                      productKey: "",
                                      serviceType: "",
                                      email: "",
                                      loginType: loginType,
                                      registeredAt: DateTime.now(),
                                      displayName: "",
                                      department: "",
                                      area: "",
                                      pin: "",
                                    ),
                                  );

                                  verified = device.pin == enteredPin;
                                }
                              }

                              setState(() => loading = false);

                              if (!ctx.mounted) return;

                              if (verified) {
                                Navigator.pop(ctx, true);
                              } else {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text("Incorrect PIN"),
                                  ),
                                );
                              }
                            },
                      child: loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Confirm"),
                    ),
                  ],
                  );
                },
              );
            },
          ) ??
          false;
    } finally {
      controller.dispose();
    }
  }
}
