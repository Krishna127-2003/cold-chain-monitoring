import 'package:flutter/material.dart';
import '../../../data/api/user_info_api.dart';
import '../../../data/session/session_manager.dart';

class PinVerifyDialog {
  static Future<bool> verify(BuildContext context) async {
    final controller = TextEditingController();
    bool loading = false;

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
                          if (email == null) return;

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

                              final email =
                                  await SessionManager.getEmail();
                              if (email == null) return;

                              final rows =
                                  await UserInfoApi.fetchByEmail(email);

                              if (!ctx.mounted) return;

                              final pinRow = rows.firstWhere(
                                (r) => r["type"] == "device_registration" &&
                                    r["pin"] != null,
                                orElse: () => {},
                              );

                              final savedPin = pinRow["pin"]?.toString();

                              setState(() => loading = false);

                              if (!ctx.mounted) return;

                              if (savedPin == enteredPin) {
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
                    )
                  ],
                );
              },
            );
          },
        ) ??
        false;
  }
}
