import 'package:flutter/material.dart';
import 'glass_card.dart';

class TemperaturePanel extends StatelessWidget {
  const TemperaturePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DEEP FREEZER -40°C",
            style: TextStyle(
              letterSpacing: 1.2,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "23.4 °C",
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              "SET 22.0 °C",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "10:42:18",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            "Tuesday, 03 February 2026",
            style: TextStyle(color: Colors.white60),
          ),

          const SizedBox(height: 10),

          const Text(
            "DEVICE ID : 5191",
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
