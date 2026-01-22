import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();

    Color bg;
    Color fg;

    if (s == "ALERT") {
      bg = const Color(0xFFFFE4E6);
      fg = const Color(0xFFBE123C);
    } else if (s == "OFFLINE") {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFF9A3412);
    } else {
      bg = const Color(0xFFECFDF3);
      fg = const Color(0xFF027A48);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        s,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
