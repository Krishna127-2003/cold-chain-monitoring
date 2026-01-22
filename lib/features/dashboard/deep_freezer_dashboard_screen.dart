// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'widgets/status_row.dart';
import 'widgets/dashboard_top_bar.dart';


class DeepFreezerDashboardScreen extends StatelessWidget {
  final String deviceId;

  const DeepFreezerDashboardScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    // Dummy values now (later from Azure)
    const pv = "-40°C";
    const sv = "-30°C";

    //final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: const DashboardTopBar(),


      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          // ✅ Premium centered layout on big screens
          final maxContentWidth = w > 600 ? 520.0 : w;

          // ✅ Responsive font scaling
          double titleSize = w < 360 ? 30 : (w < 450 ? 38 : 44);
          double pvSize = w < 360 ? 52 : (w < 450 ? 62 : 70);
          double svSize = w < 360 ? 28 : (w < 450 ? 32 : 36);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    const SizedBox(height: 18),

                    // ✅ Title + PV/SV big section
                    Text(
                      "DEEP FREEZER",
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF60A5FA),
                        letterSpacing: 2,
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

                    // ✅ Prevent PV overflow always
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        pv,
                        style: TextStyle(
                          fontSize: pvSize,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF22C55E),
                        ),
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

                    Text(
                      sv,
                      style: TextStyle(
                        fontSize: svSize,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: Colors.white.withOpacity(0.12), height: 1),
                    const SizedBox(height: 10),

                    // ✅ Status rows
                    Column(
                      children: const [
                        StatusRow(
                          icon: Icons.settings,
                          label: "Compressor",
                          value: "ON",
                          isGood: true,
                        ),
                        StatusRow(
                          icon: Icons.ac_unit,
                          label: "Defrost Auto",
                          value: "OFF",
                          isGood: false,
                        ),
                        StatusRow(
                          icon: Icons.thermostat,
                          label: "Probe",
                          value: "Fail",
                          isGood: false,
                        ),
                        StatusRow(
                          icon: Icons.insert_chart_outlined,
                          label: "Data Log",
                          value: "Fail",
                          isGood: false,
                        ),
                        StatusRow(
                          icon: Icons.door_front_door_outlined,
                          label: "Door",
                          value: "Closed",
                          isGood: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),
                    Text(
                      "Device ID: $deviceId",
                      style: const TextStyle(color: Colors.white38),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}