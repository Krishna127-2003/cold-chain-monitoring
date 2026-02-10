import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../routes/app_routes.dart';
import '../../download/download_pdf_screen.dart';

class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showTitle;
  final String? deviceId;

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

    // 📱 Dynamic logo sizing
    final double logoHeight = width < 360
        ? 26
        : width < 420
            ? 32
            : 38;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,

      /// ⬅ BACK BUTTON (fixed width – never breaks)
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Color.fromARGB(255, 2, 33, 58),
        ),
        onPressed: () => Navigator.pop(context),
      ),

      /// 🏥 RESPONSIVE LOGO (centered, auto scales)
      title: SvgPicture.asset(
        "assets/images/marken_logo.svg",
        height: logoHeight,
        fit: BoxFit.contain,
      ),

      centerTitle: true,

      actions: [
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
                  builder: (_) => DownloadPdfScreen(deviceId: deviceId!),
                ),
              );
            },
          ),

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

        const SizedBox(width: 4),
      ],
    );
  }
}
