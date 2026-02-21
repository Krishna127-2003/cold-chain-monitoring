import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';
import '../../routes/app_routes.dart';



class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {

  /// 🔥 NEW: Ask how user wants to add device
  void _chooseAddMethod(BuildContext context, String equipmentType) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "Add ${equipmentType.replaceAll("_", " ")} device",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                "Choose how you want to add the device",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              /// 📷 Scan QR
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text("Scan QR Code"),
                subtitle: const Text("Use camera to scan device QR"),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.qrScan,
                    arguments: {
                      "equipmentType": equipmentType,
                    },
                  );
                },
              ),

              const SizedBox(height: 8),

              /// ⌨️ Manual Entry
              ListTile(
                leading: const Icon(Icons.keyboard),
                title: const Text("Enter Code Manually"),
                subtitle:
                    const Text("Type device code if QR is unavailable"),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.manualEntry,
                    arguments: {
                      "equipmentType": equipmentType,
                    },
                  );
                },
              ),
            ],
          ),
        ),
        ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final pad = Responsive.pad(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Services"),
          ),
          body: Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Choose equipment type",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  "Monitor and manage your devices securely",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: width > 700 ? 3 : 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    clipBehavior: Clip.antiAlias,
                    children: [
                      _ServiceCard(
                        title: "Deep Freezer",
                        subtitle: "Ultra-low monitoring",
                        icon: Icons.ac_unit,
                        onTap: () =>
                            _chooseAddMethod(context, "DEEP_FREEZER"),
                      ),
                      _ServiceCard(
                        title: "BBR",
                        subtitle: "Blood bank safety",
                        icon: Icons.medical_services_outlined,
                        onTap: () => _chooseAddMethod(context, "BBR"),
                      ),
                      _ServiceCard(
                        title: "Platelet Incubator",
                        subtitle: "Agitation + temp control",
                        icon: Icons.science_outlined,
                        onTap: () => _chooseAddMethod(context, "PLATELET"),
                      ),
                      _ServiceCard(
                        title: "Walk-in Cooler",
                        subtitle: "Cold room monitoring",
                        icon: Icons.warehouse_outlined,
                        onTap: () =>
                            _chooseAddMethod(context, "WALK_IN_COOLER"),
                      ),
                      _ServiceCard(
                        title: "Data Logger ULT",
                        subtitle: "16 Sensor Monitoring",
                        icon: Icons.device_thermostat,
                        onTap: () => _chooseAddMethod(context, "DATA_LOGGER_ULT"),
                      ),
                      _ServiceCard(
                        title: "Active Coolpod",
                        subtitle: "Portable cooling monitoring",
                        icon: Icons.ac_unit_outlined,
                        onTap: () => _chooseAddMethod(context, "ACTIVE_COOLPOD"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/* ---------------- THEME BUTTON & CARD ---------------- */

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
               Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
