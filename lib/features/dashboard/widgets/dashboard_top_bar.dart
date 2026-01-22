import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../routes/app_routes.dart';

class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showTitle;

  const DashboardTopBar({
    super.key,
    this.title = "",
    this.showTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0A1020),
      elevation: 0,

      // ✅ Keep logo fixed at top-left
      leadingWidth: 120, // gives space for logo (and optional text later)
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
              const Text(
                "Power: OK",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 14),

              const Icon(Icons.battery_4_bar, color: Colors.orangeAccent),
              const SizedBox(width: 6),
              const Text(
                "50%",
                style: TextStyle(
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
