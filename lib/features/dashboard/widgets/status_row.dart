// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  /// ✅ default good/bad logic (still supported)
  final bool isGood;

  /// 🎨 optional custom color (for alarms, warnings, temp etc)
  final Color? valueColor;

  const StatusRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isGood,
    this.valueColor, // 👈 new (optional)
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    // 📱 responsive sizing
    final iconBox = w < 360 ? 34.0 : 38.0;
    final fontSize = w < 360 ? 15.5 : 18.0;
    final verticalPad = w < 360 ? 10.0 : 14.0;
    final gap = w < 360 ? 10.0 : 14.0;

    // 🎯 final color resolution
    final resolvedColor = valueColor ??
        (isGood
            ? const Color(0xFF22C55E) // green
            : const Color(0xFFEF4444)); // red

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPad),
            child: Row(
        children: [
          Container(
            height: iconBox,
            width: iconBox,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.9),
              size: w < 360 ? 18 : 20,
            ),
          ),

          SizedBox(width: gap),

          // 🏷 label
          Expanded(
            child: Text(
              "$label:",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // 📊 value (auto shrink if long like "LOW BATTERY")
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                color: resolvedColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
