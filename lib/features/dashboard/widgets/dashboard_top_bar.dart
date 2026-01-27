import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../routes/app_routes.dart';

class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showTitle;

  /// ✅ NEW: dynamic top right values
  final String powerText;   // ex: "Power: OK"
  final String batteryText; // ex: "80%"

  const DashboardTopBar({
    super.key,
    this.title = "",
    this.showTitle = false,
    this.powerText = "Power: --",
    this.batteryText = "--%",
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  IconData _batteryIcon(String battery) {
    final digits = battery.replaceAll("%", "").trim();
    final p = int.tryParse(digits);

    if (p == null) return Icons.battery_unknown;
    if (p >= 90) return Icons.battery_full;
    if (p >= 70) return Icons.battery_6_bar;
    if (p >= 50) return Icons.battery_4_bar;
    if (p >= 30) return Icons.battery_2_bar;
    return Icons.battery_0_bar;
  }

  Color _batteryColor(String battery) {
    final digits = battery.replaceAll("%", "").trim();
    final p = int.tryParse(digits);

    if (p == null) return Colors.white70;
    if (p >= 50) return Colors.greenAccent;
    if (p >= 25) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0A1020),
      elevation: 0,

      // ✅ Keep logo fixed at top-left
      leadingWidth: 120,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SvgPicture.asset(
            "assets/images/marken_logo.svg",
            height: 34,
          ),
        ),
      ),

      // ✅ No title to avoid pushing logo
      title: showTitle && title.isNotEmpty
          ? Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            )
          : null,

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Row(
            children: [
              /// ✅ POWER (dynamic)
              Text(
                powerText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 14),

              /// ✅ BATTERY (dynamic)
              Icon(
                _batteryIcon(batteryText),
                color: _batteryColor(batteryText),
              ),
              const SizedBox(width: 6),
              Text(
                batteryText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == "saved_devices") {
                    Navigator.pushNamed(context, AppRoutes.allDevices);
                  } else if (value == "add_new_device") {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.services,
                      (route) => false,
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: "saved_devices",
                    child: Text("Saved Devices"),
                  ),
                  PopupMenuItem(
                    value: "add_new_device",
                    child: Text("Add New Device"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}