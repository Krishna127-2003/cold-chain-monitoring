Duration levelToDelay(int level) {
  switch (level) {
    case 0:
      return Duration.zero;        // instant
    case 1:
      return const Duration(hours: 1); // 1 hour
    case 2:
      return const Duration(days: 365); // effectively never
    default:
      return const Duration(hours: 1);
  }
}
