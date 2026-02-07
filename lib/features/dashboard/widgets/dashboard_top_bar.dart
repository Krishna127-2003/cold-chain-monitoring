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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // 📱 Responsive values
    final bool isSmallMobile = width < 360;
    final bool isTabletOrWeb = width > 600;

    final double logoHeight =
        isSmallMobile ? 32 : (isTabletOrWeb ? 44 : 38);

    return AppBar(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      elevation: 0,
      automaticallyImplyLeading: false,

      /// ⬅️ LOGO (clean — no heavy styling)
      leadingWidth: isTabletOrWeb ? 160 : 140,
      leading: Padding(
        padding: const EdgeInsets.only(left: 28),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SvgPicture.asset(
            "assets/images/marken_logo.svg",
            height: logoHeight,

          ),
        ),
      ),

      /// Optional title (unchanged)
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

      /// 👉 Right-side status + menu (power removed)
      actions: [
  Padding(
    padding: const EdgeInsets.only(right: 10),
    child: Row(
      children: [

        // ⬇️ DOWNLOAD BUTTON (NEW — moved out of menu)
        if (deviceId != null)
          IconButton(
            icon: const Icon(
              Icons.download_rounded,
              color: Color.fromARGB(255, 2, 33, 58),
              size: 26,
            ),
            tooltip: "Download Data Log",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DownloadPdfScreen(
                    deviceId: deviceId!,
                  ),
                ),
              );
            },
          ),

        const SizedBox(width: 6),

        /// ☰ MENU (unchanged)
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.list_alt_sharp,
            color: Color.fromARGB(255, 2, 33, 58),
          ),
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
