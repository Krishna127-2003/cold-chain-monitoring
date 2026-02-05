import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../routes/app_routes.dart';
import '../../download/download_pdf_screen.dart';

class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showTitle;
  final String? deviceId;

  /// ✅ dynamic top-right values
  final String powerText;
  final String batteryText;

  const DashboardTopBar({
    super.key,
    this.title = "",
    this.showTitle = false,
    this.powerText = "Power: --",
    this.batteryText = "--%",
    this.deviceId,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // 🔋 Battery icon based on %
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
    final width = MediaQuery.of(context).size.width;

    // 📱 Responsive values
    final bool isSmallMobile = width < 360;
    final bool isTabletOrWeb = width > 600;

    final double logoHeight =
        isSmallMobile ? 26 : (isTabletOrWeb ? 36 : 30);

    final EdgeInsets logoPadding = EdgeInsets.symmetric(
      horizontal: isSmallMobile ? 10 : (isTabletOrWeb ? 16 : 12),
      vertical: isSmallMobile ? 6 : (isTabletOrWeb ? 10 : 8),
    );

    final double borderRadius =
        isSmallMobile ? 12 : (isTabletOrWeb ? 18 : 14);

    return AppBar(
      backgroundColor: const Color(0xFF0A1020),
      elevation: 0,
      automaticallyImplyLeading: false,

      /// ⬅️ LOGO (Auth-style, responsive)
      leadingWidth: isTabletOrWeb ? 160 : 140,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: logoPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ],
            ),
            child: SvgPicture.asset(
              "assets/images/marken_logo.svg",
              height: logoHeight,
            ),
          ),
        ),
      ),

      /// Optional title (rarely used, kept safe)
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

      /// 👉 Right-side status + menu
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Row(
            children: [
              /// 🔌 Power
              Text(
                powerText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 14),

              /// 🔋 Battery
              Icon(
                _batteryIcon(batteryText),
                color: _batteryColor(batteryText),
                size: 20,
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

              /// ☰ Menu
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
                  } else if (value == "download_pdf" && deviceId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DownloadPdfScreen(
                          deviceId: deviceId!,
                        ),
                      ),
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
                  PopupMenuItem(
                    value: "download_pdf",
                    child: Text("Download Data Log"),
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
