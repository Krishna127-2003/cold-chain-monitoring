// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'widgets/dashboard_top_bar.dart';
import 'widgets/status_row.dart';

class BbrDashboardScreen extends StatelessWidget {
  final String deviceId;

  const BbrDashboardScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    // ✅ Dummy values (later we fetch from Azure)
    const pv = "4°C";
    const sv = "5°C";

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: const DashboardTopBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 18),

            // ✅ Title + PV/SV section (Deep Freezer style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  const Text(
                    "BLOOD BAG REFRIGERATOR",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF60A5FA),
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    "PV",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    pv,
                    style: const TextStyle(
                      fontSize: 70,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    "SV",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),

                  const Text(
                    sv,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.white.withOpacity(0.12), height: 1),
            const SizedBox(height: 10),

            // ✅ Status list (taken from your BBR reference)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: const [
                  StatusRow(
                    icon: Icons.settings,
                    label: "Compressor",
                    value: "ON",
                    isGood: true,
                  ),
                  StatusRow(
                    icon: Icons.local_fire_department_outlined,
                    label: "Heater",
                    value: "OFF",
                    isGood: true,
                  ),
                  StatusRow(
                    icon: Icons.thermostat,
                    label: "Probe",
                    value: "OK",
                    isGood: true,
                  ),
                  StatusRow(
                    icon: Icons.door_front_door_outlined,
                    label: "Door",
                    value: "Closed",
                    isGood: true,
                  ),
                  StatusRow(
                    icon: Icons.insert_chart_outlined,
                    label: "Data Log",
                    value: "OK",
                    isGood: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // ✅ Device ID footer
            Text(
              "Device ID: $deviceId",
              style: const TextStyle(color: Colors.white38),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}
