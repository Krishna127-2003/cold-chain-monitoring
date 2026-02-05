import 'package:flutter/material.dart';

class LastSyncRow extends StatelessWidget {
  final DateTime? lastSync;
  final bool loading;

  const LastSyncRow({
    super.key,
    required this.lastSync,
    required this.loading,
  });

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inSeconds < 10) return "a few seconds ago";
    if (diff.inSeconds < 60) return "${diff.inSeconds} sec ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    return "${diff.inDays} days ago";
  }

  bool isStale() {
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync!).inMinutes > 5;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text("Currently syncing..."),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.sync, size: 14, color: Colors.white54),
        const SizedBox(width: 6),
        Text(
          lastSync == null
              ? "Last sync: Never"
              : "Last sync: ${_timeAgo(lastSync!)}",
          style: TextStyle(
            color: isStale() ? Colors.orangeAccent : Colors.white54,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
