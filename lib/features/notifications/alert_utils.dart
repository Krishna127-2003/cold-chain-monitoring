Duration levelToDelay(int level) {
  switch (level) {
    case 0:
      return Duration.zero; // instant
    case 1:
      return const Duration(seconds: 10);
    case 2:
      return const Duration(seconds: 20);
    case 3:
      return const Duration(seconds: 30);
    case 4:
      return const Duration(hours: 12);
    case 5:
      return const Duration(hours: 24);
    default:
      return const Duration(hours: 1);
  }
}
