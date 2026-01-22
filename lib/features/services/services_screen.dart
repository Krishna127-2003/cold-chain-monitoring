import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/responsive.dart';
import '../../core/theme/theme_provider.dart';
import '../../routes/app_routes.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  void _openDevices(BuildContext context, String equipmentType) {
    Navigator.pushNamed(
      context,
      AppRoutes.devices, // ✅ THIS IS YOUR EXISTING ROUTE
      arguments: {"equipmentType": equipmentType},
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pad(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Services"),
        actions: const [
          _ThemeMenuButton(),
          SizedBox(width: 6),
        ],
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
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: .80,
                children: [
                  _ServiceCard(
                    title: "Deep Freezer",
                    subtitle: "Ultra-low monitoring",
                    icon: Icons.ac_unit,
                    onTap: () => _openDevices(context, "DEEP_FREEZER"),
                  ),
                  _ServiceCard(
                    title: "BBR",
                    subtitle: "Blood bank safety",
                    icon: Icons.medical_services_outlined,
                    onTap: () => _openDevices(context, "BBR"),
                  ),
                  _ServiceCard(
                    title: "Platelet Incubator",
                    subtitle: "Agitation + temp control",
                    icon: Icons.science_outlined,
                    onTap: () => _openDevices(context, "PLATELET"),
                  ),
                  _ServiceCard(
                    title: "Walk-in Cooler",
                    subtitle: "Cold room monitoring",
                    icon: Icons.warehouse_outlined,
                    onTap: () => _openDevices(context, "WALK_IN_COOLER"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeMenuButton extends StatelessWidget {
  const _ThemeMenuButton();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    IconData icon;
    if (themeProvider.mode == ThemeMode.dark) {
      icon = Icons.dark_mode;
    } else if (themeProvider.mode == ThemeMode.light) {
      icon = Icons.light_mode;
    } else {
      icon = Icons.brightness_auto;
    }

    return PopupMenuButton<String>(
      tooltip: "Theme",
      icon: Icon(icon),
      onSelected: (value) {
        if (value == "light") {
          themeProvider.setTheme(ThemeMode.light);
        } else if (value == "dark") {
          themeProvider.setTheme(ThemeMode.dark);
        } else {
          themeProvider.setTheme(ThemeMode.system);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: "system", child: Text("System Default")),
        PopupMenuItem(value: "light", child: Text("Light Mode")),
        PopupMenuItem(value: "dark", child: Text("Dark Mode")),
      ],
    );
  }
}

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

              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // ✅ Important fix: Expanded instead of Spacer()
              Expanded(
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
